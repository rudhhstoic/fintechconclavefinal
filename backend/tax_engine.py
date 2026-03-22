# tax_engine.py  ─  Complete CA-grade Indian Tax Engine  FY 2024-25
# ═══════════════════════════════════════════════════════════════════
# Every deduction/exemption available under Indian Income Tax Act:
#
#  EXEMPTIONS: 10(13A) HRA · 10(5) LTA · Standard Deduction
#
#  CHAPTER VI-A (Old Regime only):
#    80C · 80CCD(1) · 80CCD(1B) · 80CCD(2)
#    80D · 80DD · 80DDB · 80E · 80EE · 80EEA · 80EEB
#    80G · 80GG · 80TTA · 80TTB · 80U · Section 24(b)
#
#  CAPITAL GAINS:
#    STCG Sec 111A (equity 20%) · LTCG Sec 112A (12.5% above 1.25L)
#    STCG other (slab) · LTCG other (20%)
#
#  BUSINESS/FREELANCER: Sec 44ADA / 44AD presumptive
#  REGIME COMPARISON · SURCHARGE · CESS · REBATE 87A
#  PERSONALISED CA ADVICE  (priority-ranked, rupee-quantified)
# ═══════════════════════════════════════════════════════════════════

from flask import Blueprint, request, jsonify

tax_bp = Blueprint('tax', __name__)

# ─── CONSTANTS FY 2024-25 ─────────────────────────────────────────
STANDARD_DEDUCTION   = 75_000      # Budget 2024 raised 50k → 75k
SEC_80C_LIMIT        = 150_000
SEC_80CCD1B_LIMIT    = 50_000
SEC_80D_SELF         = 25_000
SEC_80D_SELF_SR      = 50_000
SEC_80D_PARENTS      = 25_000
SEC_80D_PARENTS_SR   = 50_000
SEC_80DD_NORMAL      = 75_000
SEC_80DD_SEVERE      = 125_000
SEC_80DDB_NORMAL     = 40_000
SEC_80DDB_SR         = 100_000
SEC_80EE_LIMIT       = 50_000
SEC_80EEA_LIMIT      = 150_000
SEC_80EEB_LIMIT      = 150_000
SEC_80GG_LIMIT       = 60_000      # 5000/month max
SEC_80TTA_LIMIT      = 10_000
SEC_80TTB_LIMIT      = 50_000
SEC_80U_NORMAL       = 75_000
SEC_80U_SEVERE       = 125_000
SEC_24B_SELF_OCC     = 200_000

OLD_BASIC_BELOW60    = 250_000
OLD_BASIC_60TO80     = 300_000
OLD_BASIC_ABOVE80    = 500_000
OLD_87A_LIMIT        = 500_000
OLD_87A_MAX          = 12_500
NEW_87A_LIMIT        = 700_000
NEW_87A_MAX          = 25_000
CESS_RATE            = 0.04

SURCHARGE_SLABS = [
    (5_000_000,  10_000_000, 0.10),
    (10_000_000, 20_000_000, 0.15),
    (20_000_000, 50_000_000, 0.25),
    (50_000_000, float('inf'), 0.37),
]

STCG_EQUITY_RATE    = 0.20    # Budget 2024
LTCG_EQUITY_RATE    = 0.125   # Budget 2024
LTCG_EQUITY_EXEMPT  = 125_000 # Budget 2024
LTCG_OTHER_RATE     = 0.20


# ─── SLAB CALCULATORS ─────────────────────────────────────────────
def _apply_slabs(income, slabs):
    tax = 0.0
    for lo, hi, rate in slabs:
        if income <= lo:
            break
        tax += (min(income, hi) - lo) * rate
    return round(tax, 2)


def slab_old(taxable, age):
    if age >= 80:
        exempt = OLD_BASIC_ABOVE80
    elif age >= 60:
        exempt = OLD_BASIC_60TO80
    else:
        exempt = OLD_BASIC_BELOW60
    if taxable <= exempt:
        return 0.0
    return _apply_slabs(taxable, [
        (exempt,     500_000,      0.05),
        (500_000,    1_000_000,    0.20),
        (1_000_000,  float('inf'), 0.30),
    ])


def slab_new(taxable):
    return _apply_slabs(taxable, [
        (0,          300_000,      0.00),
        (300_000,    600_000,      0.05),
        (600_000,    900_000,      0.10),
        (900_000,    1_200_000,    0.15),
        (1_200_000,  1_500_000,    0.20),
        (1_500_000,  float('inf'), 0.30),
    ])


def marginal_rate_old(taxable):
    if taxable <= 250_000:   return 0.0
    if taxable <= 500_000:   return 0.05
    if taxable <= 1_000_000: return 0.20
    return 0.30


# ─── REBATE / SURCHARGE / CESS ────────────────────────────────────
def rebate_87a(taxable, tax, regime):
    if regime == 'old' and taxable <= OLD_87A_LIMIT:
        return min(tax, OLD_87A_MAX)
    if regime == 'new' and taxable <= NEW_87A_LIMIT:
        return min(tax, NEW_87A_MAX)
    return 0.0


def compute_surcharge(base_tax, gross_income, regime):
    for lo, hi, rate in SURCHARGE_SLABS:
        if lo < gross_income <= hi:
            r = min(rate, 0.25) if regime == 'new' else rate
            return round(base_tax * r, 2)
    return 0.0


def final_tax(base, taxable, gross, regime):
    reb = rebate_87a(taxable, base, regime)
    ar  = max(0.0, base - reb)
    sur = compute_surcharge(ar, gross, regime)
    pre = ar + sur
    ces = round(pre * CESS_RATE, 2)
    return {
        'base':      round(base, 2),
        'rebate':    round(reb, 2),
        'surcharge': round(sur, 2),
        'cess':      ces,
        'total':     round(pre + ces, 2),
    }


# ─── HRA EXEMPTION  Sec 10(13A) ───────────────────────────────────
def hra_exemption_calc(basic, hra_received, rent_paid, metro):
    if hra_received <= 0 or rent_paid <= 0:
        return 0.0
    pct = 0.50 if metro else 0.40
    return round(min(hra_received, basic * pct, max(0.0, rent_paid - 0.10 * basic)), 2)


# ─── CAPITAL GAINS TAX ────────────────────────────────────────────
def capital_gains_tax(cg, slab_rate):
    stcg_eq  = float(cg.get('stcg_equity', 0))
    ltcg_eq  = float(cg.get('ltcg_equity', 0))
    stcg_oth = float(cg.get('stcg_other', 0))
    ltcg_oth = float(cg.get('ltcg_other', 0))

    t_stcg_eq  = round(stcg_eq * STCG_EQUITY_RATE, 2)
    t_ltcg_eq  = round(max(0, ltcg_eq - LTCG_EQUITY_EXEMPT) * LTCG_EQUITY_RATE, 2)
    t_stcg_oth = round(stcg_oth * slab_rate, 2)
    t_ltcg_oth = round(ltcg_oth * LTCG_OTHER_RATE, 2)

    return {
        'stcg_equity_tax':  t_stcg_eq,
        'ltcg_equity_tax':  t_ltcg_eq,
        'stcg_other_tax':   t_stcg_oth,
        'ltcg_other_tax':   t_ltcg_oth,
        'total_cg_tax':     round(t_stcg_eq + t_ltcg_eq + t_stcg_oth + t_ltcg_oth, 2),
    }


# ─── PRESUMPTIVE INCOME ───────────────────────────────────────────
def presumptive_income(gross_receipts, emp_type, actual_exp):
    et = emp_type.lower()
    if et == 'freelancer':
        presumptive = gross_receipts * 0.50
    elif et == 'business':
        presumptive = gross_receipts * 0.06  # digital receipts
    else:
        return gross_receipts
    if actual_exp > 0:
        return round(min(presumptive, gross_receipts - actual_exp), 2)
    return round(presumptive, 2)


# ─── OLD REGIME FULL DEDUCTION COMPUTATION ───────────────────────
def compute_old_deductions(data, age, gross, is_salaried):
    d    = data.get('deductions', {})
    cg   = data.get('capital_gains', {})
    basic = float(data.get('income', 0))

    # 80C combined bucket (PPF, ELSS, LIC, EPF, FD-5yr, NSC, tuition fees)
    raw_80c   = float(d.get('80c', 0))
    nps_self  = min(float(d.get('nps_self', 0)), gross * 0.10)
    combined_80c = min(raw_80c + nps_self, SEC_80C_LIMIT)

    # 80CCD(1B) — NPS extra, over and above 80C
    nps_extra = min(float(d.get('nps_extra', 0)), SEC_80CCD1B_LIMIT)

    # 80CCD(2) — employer NPS (allowed in NEW regime too)
    emp_nps   = min(float(d.get('employer_nps', 0)), gross * 0.10)

    # 80D
    d80d_self    = min(float(d.get('80d_self', 0)), SEC_80D_SELF_SR if age >= 60 else SEC_80D_SELF)
    parents_age  = int(d.get('parents_age', 0))
    d80d_parents = min(float(d.get('80d_parents', 0)), SEC_80D_PARENTS_SR if parents_age >= 60 else SEC_80D_PARENTS)

    # 80DD — disabled dependent
    d80dd = min(float(d.get('80dd', 0)), SEC_80DD_SEVERE if d.get('80dd_severe') else SEC_80DD_NORMAL)

    # 80DDB — specified disease
    d80ddb = min(float(d.get('80ddb', 0)), SEC_80DDB_SR if age >= 60 else SEC_80DDB_NORMAL)

    # 80E — education loan interest (no cap)
    d80e = float(d.get('80e', 0))

    # 80EE — first homebuyer extra
    d80ee = min(float(d.get('80ee', 0)), SEC_80EE_LIMIT)

    # 80EEA — affordable housing
    d80eea = min(float(d.get('80eea', 0)), SEC_80EEA_LIMIT)

    # 80EEB — EV loan
    d80eeb = min(float(d.get('80eeb', 0)), SEC_80EEB_LIMIT)

    # 80G — donations
    d80g = float(d.get('80g', 0))

    # 80GG — rent paid (no HRA received)
    hra_recv  = float(data.get('hra', 0))
    rent_paid = float(data.get('rent_paid', 0))
    d80gg = 0.0
    if (not is_salaried or hra_recv == 0) and rent_paid > 0:
        d80gg = min(max(0, rent_paid - 0.10 * gross), SEC_80GG_LIMIT, gross * 0.25)

    # 80TTA / 80TTB
    d80tta = min(float(d.get('80tta', 0)), SEC_80TTA_LIMIT) if age < 60 else 0.0
    d80ttb = min(float(d.get('80ttb', 0)), SEC_80TTB_LIMIT) if age >= 60 else 0.0

    # 80U — self disability
    d80u = min(float(d.get('80u', 0)), SEC_80U_SEVERE if d.get('80u_severe') else SEC_80U_NORMAL)

    # Standard deduction + salary exemptions
    std_ded    = STANDARD_DEDUCTION if is_salaried else 0.0
    metro      = data.get('city_type', 'non_metro').lower() == 'metro'
    hra_exempt = hra_exemption_calc(basic, hra_recv, rent_paid, metro) if is_salaried else 0.0
    lta        = float(d.get('lta', 0))

    # Section 24(b) — home loan interest
    home_int = float(d.get('home_loan_interest', 0))
    sec24b   = min(home_int, SEC_24B_SELF_OCC)

    total = (std_ded + hra_exempt + lta + combined_80c + nps_extra + emp_nps
             + d80d_self + d80d_parents + d80dd + d80ddb + d80e + d80ee
             + d80eea + d80eeb + d80g + d80gg + d80tta + d80ttb + d80u + sec24b)

    return {
        'standard_deduction':   std_ded,
        'hra_exemption':        hra_exempt,
        'lta':                  lta,
        '80c_combined':         round(combined_80c, 2),
        'nps_extra_80ccd1b':    round(nps_extra, 2),
        'employer_nps_80ccd2':  round(emp_nps, 2),
        '80d_self':             round(d80d_self, 2),
        '80d_parents':          round(d80d_parents, 2),
        '80dd':                 round(d80dd, 2),
        '80ddb':                round(d80ddb, 2),
        '80e':                  round(d80e, 2),
        '80ee':                 round(d80ee, 2),
        '80eea':                round(d80eea, 2),
        '80eeb':                round(d80eeb, 2),
        '80g':                  round(d80g, 2),
        '80gg':                 round(d80gg, 2),
        '80tta':                round(d80tta, 2),
        '80ttb':                round(d80ttb, 2),
        '80u':                  round(d80u, 2),
        'home_loan_24b':        round(sec24b, 2),
        'total':                round(total, 2),
        # private fields for CA advice
        '_raw_80c':     raw_80c,
        '_nps_extra':   float(d.get('nps_extra', 0)),
        '_hra_recv':    hra_recv,
        '_rent_paid':   rent_paid,
        '_home_int':    home_int,
        '_parents_age': parents_age,
    }


# ─── MAIN ENGINE ──────────────────────────────────────────────────
def calculate_tax(data):
    age         = int(data.get('age', 30))
    emp_type    = data.get('employment_type', 'Salaried').strip()
    is_salaried = emp_type.lower() == 'salaried'

    basic           = float(data.get('income', 0))
    other_income    = float(data.get('other_income', 0))
    gross_receipts  = float(data.get('gross_receipts', basic))
    actual_exp      = float(data.get('actual_expenses', 0))

    business_inc = presumptive_income(gross_receipts, emp_type, actual_exp) if not is_salaried else basic
    gross        = business_inc + other_income

    cg_data  = data.get('capital_gains', {})
    cg_taxes = capital_gains_tax(cg_data, marginal_rate_old(gross))

    # OLD REGIME
    old_ded     = compute_old_deductions(data, age, gross, is_salaried)
    old_taxable = max(0.0, gross - old_ded['total'])
    old_base    = slab_old(old_taxable, age)
    old_detail  = final_tax(old_base, old_taxable, gross, 'old')
    old_total   = round(old_detail['total'] + cg_taxes['total_cg_tax'], 2)

    # NEW REGIME (only std deduction + employer NPS)
    new_std     = STANDARD_DEDUCTION if is_salaried else 0.0
    new_emp_nps = min(float(data.get('deductions', {}).get('employer_nps', 0)), gross * 0.10)
    new_taxable = max(0.0, gross - new_std - new_emp_nps)
    new_base    = slab_new(new_taxable)
    new_detail  = final_tax(new_base, new_taxable, gross, 'new')
    new_total   = round(new_detail['total'] + cg_taxes['total_cg_tax'], 2)

    best        = 'Old' if old_total <= new_total else 'New'
    savings     = round(abs(old_total - new_total), 2)
    best_taxable = old_taxable if best == 'Old' else new_taxable

    advice = generate_ca_advice(
        age, gross, best, emp_type, is_salaried,
        old_ded, cg_data, old_total, new_total, old_taxable,
        data.get('deductions', {}), data
    )

    return {
        # Flutter TaxResultModel fields
        'old_regime_tax':  old_total,
        'new_regime_tax':  new_total,
        'best_regime':     best,
        'taxable_income':  round(best_taxable, 2),
        'tax_savings':     savings,
        'recommendations': [a['advice'] for a in advice[:6]],

        # Extended CA UI
        'ca_advice':    advice,
        'capital_gains': cg_taxes,
        'breakdown': {
            'gross_income':    round(gross, 2),
            'employment_type': emp_type,
            'old_regime': {
                **{k: round(v, 2) for k, v in old_ded.items() if not k.startswith('_')},
                'taxable_income': round(old_taxable, 2),
                'base_tax':       old_detail['base'],
                'rebate_87a':     old_detail['rebate'],
                'surcharge':      old_detail['surcharge'],
                'cess':           old_detail['cess'],
                'income_tax':     old_detail['total'],
                'cg_tax':         cg_taxes['total_cg_tax'],
                'total_tax':      old_total,
            },
            'new_regime': {
                'standard_deduction': new_std,
                'employer_nps':       round(new_emp_nps, 2),
                'taxable_income':     round(new_taxable, 2),
                'base_tax':           new_detail['base'],
                'rebate_87a':         new_detail['rebate'],
                'surcharge':          new_detail['surcharge'],
                'cess':               new_detail['cess'],
                'income_tax':         new_detail['total'],
                'cg_tax':             cg_taxes['total_cg_tax'],
                'total_tax':          new_total,
            },
        },
    }


# ─── PERSONALISED CA ADVICE ───────────────────────────────────────
# KEY FIX: All tips shown for ALL users regardless of regime.
# Tips are worded to reflect whether they apply now (Old Regime)
# or as a future switch strategy (New Regime users).
def generate_ca_advice(age, gross, best, emp_type, is_salaried,
                        old_ded, cg_data, old_total, new_total,
                        old_taxable, raw_d, raw_p):
    tips = []
    # Use new regime marginal rate for New Regime users (correct for their situation)
    new_taxable = max(0, gross - (STANDARD_DEDUCTION if is_salaried else 0))
    mr_new = _marginal_rate_new(new_taxable)
    mr_old = marginal_rate_old(old_taxable)
    # Use whichever regime is best for saving calculations
    mr = mr_old if best == 'Old' else mr_new

    def sav(amount):
        # Include 4% cess effect on the saving
        return int(round(amount * mr * 1.04, 0))

    def sav_old(amount):
        # Always compute Old Regime saving (for "switch strategy" advice)
        return int(round(amount * mr_old * 1.04, 0))

    def tip(section, title, advice, potential_saving, priority, category):
        tips.append({'section': section, 'title': title, 'advice': advice,
                     'potential_saving': max(0, potential_saving),
                     'priority': priority, 'category': category})

    diff = abs(old_total - new_total)
    break_even = _break_even_deduction(gross, age)

    # ── 1. REGIME CHOICE ─────────────────────────────────────────────
    if best == 'Old':
        tip('Regime Choice', 'Old Regime is better for you',
            f"Stay on the Old Regime — your deductions of ₹{old_ded['total']:,.0f} "
            f"make it ₹{diff:,.0f} cheaper than the New Regime this year. "
            f"Review annually as slabs or your deductions change.",
            diff, 1, 'regime')
    else:
        tip('Regime Choice', 'New Regime saves you ₹{:,.0f}'.format(diff),
            f"The New Regime saves you ₹{diff:,.0f} this year. "
            f"Your current deductions (₹{old_ded['total']:,.0f}) aren't enough to make "
            f"the Old Regime competitive. You would need total deductions above "
            f"₹{break_even:,.0f} for the Old Regime to win. "
            f"The tips below show how to get there — if you invest enough, "
            f"switching to Old Regime next year could save you even more.",
            diff, 1, 'regime')

    # ── 2. SECTION 80C ───────────────────────────────────────────────
    # Show for EVERYONE — Old regime users save now, New regime users
    # can use it as a strategy to eventually switch to Old Regime.
    used_80c = old_ded['80c_combined']
    room_80c = SEC_80C_LIMIT - used_80c

    if room_80c > 0:
        if best == 'Old':
            note = f"At your tax slab this saves ₹{sav(room_80c):,.0f} immediately."
        else:
            note = (f"You're on New Regime now, so this won't reduce this year's tax. "
                    f"But investing ₹{room_80c:,.0f} in 80C + boosting other deductions to "
                    f"₹{break_even:,.0f} total would make Old Regime win by "
                    f"₹{sav_old(room_80c):,.0f} next year.")
        tip('Section 80C', f'₹{room_80c:,.0f} of 80C space is unused',
            f"You have ₹{room_80c:,.0f} left in your 80C bucket (limit: ₹1.5L). "
            f"Best options for your profile: "
            f"ELSS mutual funds (3-yr lock-in, market returns — ideal if age < 40), "
            f"PPF (15-yr, 7.1% guaranteed tax-free — ideal for conservative investors), "
            f"5-yr tax-saving FD, NSC, or topping up your life insurance premium. "
            f"{note}",
            sav_old(room_80c), 2, 'investment')

    elif used_80c >= SEC_80C_LIMIT:
        tip('Section 80C', '80C fully utilised — explore NPS 80CCD(1B) next',
            f"Your ₹1.5L 80C bucket is maxed out. Now look at Sec 80CCD(1B): "
            f"an ADDITIONAL ₹50,000 NPS deduction completely outside the 80C limit — "
            f"available in Old Regime only. "
            f"That saves ₹{sav_old(50_000):,.0f} extra and builds your retirement corpus.",
            sav_old(50_000), 2, 'retirement')

    # ── 3. NPS 80CCD(1B) — extra ₹50K ────────────────────────────────
    nps_extra_used = old_ded['nps_extra_80ccd1b']
    room_nps = SEC_80CCD1B_LIMIT - nps_extra_used
    if room_nps > 0:
        if best == 'Old':
            nps_note = f"Contributes ₹{sav(room_nps):,.0f} in tax saving this year."
        else:
            nps_note = (f"If you switch to Old Regime after maxing this + 80C, "
                        f"you'd save ₹{sav_old(room_nps):,.0f} on this deduction alone.")
        tip('Section 80CCD(1B)',
            f'NPS extra ₹{room_nps:,.0f} deduction available',
            f"Section 80CCD(1B) lets you deduct ₹{room_nps:,.0f} more through NPS Tier-I "
            f"contributions — completely separate from your ₹1.5L 80C limit. "
            f"Opens a dedicated pension corpus with equity/debt options. "
            f"{nps_note}",
            sav_old(room_nps), 3, 'retirement')

    # ── 4. HEALTH INSURANCE — 80D SELF ───────────────────────────────
    d_self_lim = SEC_80D_SELF_SR if age >= 60 else SEC_80D_SELF
    room_80d = d_self_lim - old_ded['80d_self']
    if room_80d > 0:
        if best == 'Old':
            d_note = f"Saves ₹{sav(room_80d):,.0f} in tax this year."
        else:
            d_note = (f"Currently you're on New Regime (no 80D benefit). "
                      f"But health cover protects against medical costs regardless.")
        tip('Section 80D',
            f'Health insurance gap — ₹{room_80d:,.0f} more deduction possible',
            f"You can claim ₹{room_80d:,.0f} more under Section 80D "
            f"(limit: ₹{d_self_lim:,.0f} for {'senior citizens' if age >= 60 else 'individuals'}). "
            f"A ₹5–10L family floater policy typically costs ₹8,000–15,000/yr. "
            f"{d_note} "
            f"Regardless of tax regime, health insurance protects against catastrophic medical costs.",
            sav_old(room_80d), 3, 'insurance')

    # ── 5. PARENTS HEALTH INSURANCE — 80D ────────────────────────────
    parents_age = old_ded['_parents_age']
    if old_ded['80d_parents'] == 0:
        p_lim = SEC_80D_PARENTS_SR if parents_age >= 60 else SEC_80D_PARENTS
        p_label = 'Senior citizen parents (60+) — ₹50,000 limit' if parents_age >= 60 else 'Parents below 60 — ₹25,000 limit'
        tip('Section 80D (Parents)',
            f'Parents health insurance — ₹{sav_old(p_lim):,.0f} in potential saving',
            f"Add your parents to a separate health insurance plan. "
            f"{p_label}. "
            f"A ₹3L policy for parents costs ~₹{p_lim // 6:,.0f}/yr and "
            f"saves ₹{sav_old(p_lim):,.0f} in Old Regime tax — essentially free medical cover. "
            f"Even in New Regime, the cover itself is valuable independent of the tax benefit.",
            sav_old(p_lim), 3, 'insurance')

    # ── 6. HRA EXEMPTION ─────────────────────────────────────────────
    # Shown to everyone who pays rent but doesn't claim HRA
    if is_salaried and old_ded['hra_exemption'] == 0:
        metro = raw_p.get('city_type', 'non_metro').lower() == 'metro'
        pct = 50 if metro else 40
        basic = float(raw_p.get('income', 0))
        rent = float(raw_p.get('rent_paid', 0))
        if rent > 0:
            # Compute approximate exemption
            est_exempt = min(
                basic * 0.3,                    # rough HRA received estimate
                basic * (pct / 100),
                max(0, rent - 0.10 * basic)
            )
        else:
            est_exempt = basic * (pct / 100) * 0.35  # estimate if rent not entered
        tip('Section 10(13A) HRA',
            'Claim HRA exemption — not claimed yet',
            f"You have not claimed any HRA exemption. "
            f"If you pay rent, ask HR to restructure your salary to include HRA, "
            f"then submit monthly rent receipts. "
            f"The exemption = minimum of (actual HRA, {pct}% of basic, rent paid − 10% of basic). "
            f"Landlord PAN mandatory if annual rent exceeds ₹1L. "
            f"This benefit applies in the Old Regime only — "
            f"estimated saving: ₹{sav_old(int(est_exempt)):,}+.",
            sav_old(int(est_exempt)), 2, 'housing')

    # ── 7. HOME LOAN INTEREST — 24(b) ────────────────────────────────
    home_int = old_ded['_home_int']
    if home_int == 0 and gross > 400_000:
        tip('Section 24(b)',
            'Home loan interest up to ₹2L is fully deductible (Old Regime)',
            f"If you have or plan to take a home loan on a self-occupied property, "
            f"interest paid (up to ₹2L/yr) is deductible under Sec 24(b) — Old Regime only. "
            f"Saving: ₹{sav_old(200_000):,.0f}/yr. "
            f"For a let-out property: no cap at all — the full interest is deductible "
            f"against rental income in both regimes.",
            sav_old(200_000), 4, 'housing')
    elif home_int > SEC_24B_SELF_OCC:
        excess = home_int - SEC_24B_SELF_OCC
        tip('Section 24(b)',
            'Home loan interest exceeds the ₹2L cap',
            f"Your home loan interest of ₹{home_int:,.0f} exceeds the ₹2L self-occupied limit. "
            f"₹{excess:,.0f} is currently unclaimed. "
            f"If the property is let-out or deemed let-out, the FULL interest "
            f"is deductible with no ceiling. Reclassifying could save ₹{sav_old(int(excess)):,.0f}.",
            sav_old(int(excess)), 3, 'housing')

    # ── 8. AFFORDABLE HOUSING — 80EEA ────────────────────────────────
    if float(raw_d.get('80eea', 0)) == 0 and gross < 5_000_000:
        tip('Section 80EEA',
            'First-time homebuyer? Extra ₹1.5L deduction (Old Regime)',
            f"If you bought your first home with a loan sanctioned between 2019–2022, "
            f"with stamp duty value ≤ ₹45L, you qualify for an ADDITIONAL ₹1.5L deduction "
            f"under Sec 80EEA — over and above the ₹2L Sec 24(b) limit. "
            f"Potential saving in Old Regime: ₹{sav_old(150_000):,.0f}.",
            sav_old(150_000), 5, 'housing')

    # ── 9. ELECTRIC VEHICLE LOAN — 80EEB ─────────────────────────────
    if float(raw_d.get('80eeb', 0)) == 0:
        tip('Section 80EEB',
            'EV loan interest — ₹1.5L deduction (Old Regime)',
            f"Financing an electric vehicle? Interest on EV loans qualifies for ₹1.5L "
            f"deduction under Sec 80EEB — two-wheelers and four-wheelers both included. "
            f"Saving in Old Regime: ₹{sav_old(150_000):,.0f}. "
            f"Combines green mobility with smart tax planning.",
            sav_old(150_000), 6, 'investment')

    # ── 10. EDUCATION LOAN — 80E ──────────────────────────────────────
    if float(raw_d.get('80e', 0)) == 0 and age <= 40:
        tip('Section 80E',
            'Education loan interest — unlimited deduction for 8 years (Old Regime)',
            f"If you or your children have a higher education loan, "
            f"100% of the interest paid is deductible under Sec 80E with NO upper limit "
            f"for up to 8 consecutive years from repayment start. "
            f"₹60,000 in interest saves ₹{sav_old(60_000):,.0f} in Old Regime.",
            sav_old(60_000), 5, 'investment')

    # ── 11. CHARITABLE DONATIONS — 80G ───────────────────────────────
    if float(raw_d.get('80g', 0)) == 0:
        tip('Section 80G',
            'Donations to approved funds — 50–100% deductible (Old Regime)',
            f"PM Relief Fund, National Defence Fund: 100% deductible. "
            f"Approved NGOs and charitable trusts: 50% deductible. "
            f"Always donate by cheque/UPI (cash deduction limited to ₹2,000). "
            f"Keep the 80G certificate — ₹20,000 donation saves ₹{sav_old(10_000):,.0f} (at 50%).",
            sav_old(10_000), 7, 'investment')

    # ── 12. SAVINGS INTEREST — 80TTA / 80TTB ─────────────────────────
    if age < 60 and old_ded['80tta'] == 0:
        tip('Section 80TTA',
            '₹10,000 savings bank interest is tax-free (Old Regime)',
            f"Interest earned on savings accounts (not FDs) is exempt up to ₹10,000 "
            f"under Sec 80TTA — Old Regime only. "
            f"Move idle money to high-yield savings accounts "
            f"(small finance banks offer 6–7% p.a.). "
            f"Saving: ₹{sav_old(10_000):,.0f}.",
            sav_old(10_000), 7, 'investment')

    # ── 13. SENIOR CITIZEN BENEFITS ───────────────────────────────────
    if age >= 60:
        tip('Section 80TTB',
            'Senior citizen: all interest income up to ₹50K tax-free',
            f"ALL interest income (savings + FDs + RDs + post office deposits) "
            f"up to ₹50,000 is exempt under Sec 80TTB — Old Regime. "
            f"TDS on bank interest also exempt up to ₹50K under Sec 194A. "
            f"Saving: ₹{sav_old(50_000):,.0f}.",
            sav_old(50_000), 3, 'senior')

        tip('Senior Citizen Schemes',
            'SCSS at 8.2% p.a. — best risk-free return + qualifies for 80C',
            f"Senior Citizen Savings Scheme (SCSS): 8.2% interest, quarterly payout, "
            f"up to ₹30L deposit, fully qualifies for 80C (within ₹1.5L limit). "
            f"Pradhan Mantri Vaya Vandana Yojana (PMVVY) for pension income. "
            f"Both government-backed — safer than FDs with better returns.",
            0, 3, 'senior')

    # ── 14. FREELANCER / BUSINESS SPECIFIC ───────────────────────────
    if not is_salaried:
        if emp_type.lower() == 'freelancer':
            tip('Section 44ADA',
                'Freelancer: track actual expenses vs 50% presumptive',
                f"Under Sec 44ADA, 50% of gross receipts is deemed profit automatically. "
                f"But if your real expenses (internet, laptop, workspace, software, "
                f"professional subscriptions, travel for work) exceed 50% of receipts, "
                f"maintain books and file ITR-3 with actual lower profit. "
                f"Your 80C, NPS, health insurance deductions still apply on top.",
                0, 2, 'business')
        else:
            tip('Section 44AD',
                'Business: digital receipts taxed at 6%, cash at 8%',
                f"Under Sec 44AD, digital/cheque receipts attract only 6% deemed profit "
                f"(cash: 8%) — no books required up to ₹2Cr turnover. "
                f"On ₹50L turnover, digital = ₹3L taxable vs ₹4L for cash. "
                f"Saves ~₹20,800 in tax. Ensure all payments received through bank/UPI.",
                20_800, 2, 'business')

        tip('Advance Tax',
            'Pay advance tax — avoid 234B/234C interest penalty',
            f"Non-salaried taxpayers must pay advance tax in instalments: "
            f"15% by Jun 15 · 45% by Sep 15 · 75% by Dec 15 · 100% by Mar 15. "
            f"Missing any deadline triggers 1% per month interest (Sec 234B/234C). "
            f"On ₹1L total tax that's ₹12,000/yr in completely avoidable penalties.",
            1_200, 4, 'compliance')

    # ── 15. CAPITAL GAINS ─────────────────────────────────────────────
    stcg_eq = float(cg_data.get('stcg_equity', 0))
    ltcg_eq = float(cg_data.get('ltcg_equity', 0))

    if stcg_eq > 0:
        saving_if_held = int(round(stcg_eq * (STCG_EQUITY_RATE - LTCG_EQUITY_RATE), 0))
        tip('Capital Gains — STCG',
            f'Hold equity > 1 year to cut tax from 20% to 12.5%',
            f"Your ₹{stcg_eq:,.0f} in short-term equity gains is taxed at 20% (STCG). "
            f"If you hold the same positions for 12+ months they qualify as LTCG at 12.5%. "
            f"Holding saves ₹{saving_if_held:,.0f}. "
            f"Also consider selling any loss-making positions before year-end to "
            f"offset these gains — this is called tax-loss harvesting.",
            saving_if_held, 3, 'capital_gains')

    if ltcg_eq > LTCG_EQUITY_EXEMPT:
        excess = ltcg_eq - LTCG_EQUITY_EXEMPT
        tip('Capital Gains — LTCG Harvesting',
            f'Book ₹1.25L in gains every March — permanently resets cost basis',
            f"₹{LTCG_EQUITY_EXEMPT:,.0f} of LTCG per year is completely tax-free. "
            f"You have ₹{excess:,.0f} above this threshold (tax: ₹{int(round(excess * LTCG_EQUITY_RATE,0)):,.0f}). "
            f"Strategy: each year before 31 March, sell and immediately repurchase holdings "
            f"to book exactly ₹1.25L in gains — pays zero tax, resets your cost basis higher, "
            f"and permanently avoids future LTCG on that appreciation.",
            int(round(excess * LTCG_EQUITY_RATE, 0)), 3, 'capital_gains')

    # ── 16. SURCHARGE WARNING ─────────────────────────────────────────
    if gross > 5_000_000:
        tip('Surcharge Planning',
            'Income > ₹50L — 10% surcharge applies on your tax',
            f"Your income attracts a 10% surcharge on top of base tax. "
            f"Mitigation strategies: "
            f"(1) Tax-free bonds (NHAI/REC/PFC) — interest exempt under Sec 10(15); "
            f"(2) Maximise NPS — no surcharge on NPS contributions; "
            f"(3) LTCG instruments — surcharge capped at 15% for these; "
            f"(4) Check marginal relief near ₹50L threshold — a small income reduction "
            f"can save a disproportionately large surcharge amount.",
            0, 2, 'investment')

    # ── 17. ITR FILING ────────────────────────────────────────────────
    tip('ITR Filing',
        'File ITR by 31 July — mandatory to carry forward losses',
        f"File before 31 July to avoid ₹5,000 late fee (Sec 234F). "
        f"Filing on time is the ONLY way to carry forward capital losses "
        f"(allowed up to 8 years). Cross-check Form 26AS and AIS "
        f"before submitting — any mismatch with your return triggers notices. "
        f"ITR also strengthens your profile for visa applications, loans, and credit cards.",
        0, 8, 'compliance')

    tips.sort(key=lambda x: (x['priority'], -x['potential_saving']))
    return tips


def _marginal_rate_new(taxable):
    """Marginal rate under New Regime."""
    if taxable <= 300_000:   return 0.0
    if taxable <= 600_000:   return 0.05
    if taxable <= 900_000:   return 0.10
    if taxable <= 1_200_000: return 0.15
    if taxable <= 1_500_000: return 0.20
    return 0.30


def _break_even_deduction(gross, age):
    """Minimum deductions needed for Old Regime to equal New Regime tax."""
    new_tax = final_tax(slab_new(max(0, gross - STANDARD_DEDUCTION)), max(0, gross - STANDARD_DEDUCTION), gross, 'new')['total']
    # Binary search for break-even deduction amount
    lo, hi = 0, gross
    for _ in range(40):
        mid = (lo + hi) / 2
        old_t = max(0, gross - mid)
        old_tax = final_tax(slab_old(old_t, age), old_t, gross, 'old')['total']
        if old_tax <= new_tax:
            hi = mid
        else:
            lo = mid
    return round(hi, 0)


# ─── FLASK ROUTE ──────────────────────────────────────────────────
@tax_bp.route('/calculate_tax', methods=['POST'])
def calculate_tax_route():
    data = request.get_json(silent=True)
    if not data:
        return jsonify({'error': 'No JSON body received'}), 400
    if float(data.get('income', 0)) <= 0 and float(data.get('gross_receipts', 0)) <= 0:
        return jsonify({'error': 'income or gross_receipts must be positive'}), 422
    age = int(data.get('age', 0))
    if not (1 <= age <= 120):
        return jsonify({'error': 'age must be between 1 and 120'}), 422
    try:
        return jsonify(calculate_tax(data)), 200
    except (ValueError, TypeError) as e:
        return jsonify({'error': f'Invalid input: {e}'}), 422
    except Exception as e:
        return jsonify({'error': f'Tax calculation failed: {e}'}), 500