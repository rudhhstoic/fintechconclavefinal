// tax_planner_model.dart
// Extended model — matches full tax_engine.py CA response.

class TaxInputModel {
  final int age;
  final String employmentType;
  final String cityType;
  final double annualIncome;
  final double grossReceipts;
  final double actualExpenses;
  final double hra;
  final double rentPaid;
  final double otherIncome;
  final double d80c;
  final double npsSelf;
  final double npsExtra;
  final double employerNps;
  final double d80dSelf;
  final double d80dParents;
  final int parentsAge;
  final double d80dd;
  final bool d80ddSevere;
  final double d80ddb;
  final double d80e;
  final double d80ee;
  final double d80eea;
  final double d80eeb;
  final double d80g;
  final double d80tta;
  final double d80ttb;
  final double d80u;
  final bool d80uSevere;
  final double lta;
  final double homeLoanInterest;
  final double stcgEquity;
  final double ltcgEquity;
  final double stcgOther;
  final double ltcgOther;

  TaxInputModel({
    required this.age,
    required this.employmentType,
    this.cityType = 'non_metro',
    required this.annualIncome,
    this.grossReceipts = 0,
    this.actualExpenses = 0,
    this.hra = 0,
    this.rentPaid = 0,
    this.otherIncome = 0,
    this.d80c = 0,
    this.npsSelf = 0,
    this.npsExtra = 0,
    this.employerNps = 0,
    this.d80dSelf = 0,
    this.d80dParents = 0,
    this.parentsAge = 0,
    this.d80dd = 0,
    this.d80ddSevere = false,
    this.d80ddb = 0,
    this.d80e = 0,
    this.d80ee = 0,
    this.d80eea = 0,
    this.d80eeb = 0,
    this.d80g = 0,
    this.d80tta = 0,
    this.d80ttb = 0,
    this.d80u = 0,
    this.d80uSevere = false,
    this.lta = 0,
    this.homeLoanInterest = 0,
    this.stcgEquity = 0,
    this.ltcgEquity = 0,
    this.stcgOther = 0,
    this.ltcgOther = 0,
  });

  Map<String, dynamic> toJson() => {
        'age': age,
        'employment_type': employmentType,
        'city_type': cityType,
        'income': annualIncome,
        'gross_receipts': grossReceipts > 0 ? grossReceipts : annualIncome,
        'actual_expenses': actualExpenses,
        'hra': hra,
        'rent_paid': rentPaid,
        'other_income': otherIncome,
        'deductions': {
          '80c': d80c,
          'nps_self': npsSelf,
          'nps_extra': npsExtra,
          'employer_nps': employerNps,
          '80d_self': d80dSelf,
          '80d_parents': d80dParents,
          'parents_age': parentsAge,
          '80dd': d80dd,
          '80dd_severe': d80ddSevere,
          '80ddb': d80ddb,
          '80e': d80e,
          '80ee': d80ee,
          '80eea': d80eea,
          '80eeb': d80eeb,
          '80g': d80g,
          '80tta': d80tta,
          '80ttb': d80ttb,
          '80u': d80u,
          '80u_severe': d80uSevere,
          'lta': lta,
          'home_loan_interest': homeLoanInterest,
        },
        'capital_gains': {
          'stcg_equity': stcgEquity,
          'ltcg_equity': ltcgEquity,
          'stcg_other': stcgOther,
          'ltcg_other': ltcgOther,
        },
      };
}

class CaAdviceItem {
  final String section;
  final String title;
  final String advice;
  final double potentialSaving;
  final int priority;
  final String category;

  CaAdviceItem({
    required this.section,
    required this.title,
    required this.advice,
    required this.potentialSaving,
    required this.priority,
    required this.category,
  });

  factory CaAdviceItem.fromJson(Map<String, dynamic> j) => CaAdviceItem(
        section: j['section'] ?? '',
        title: j['title'] ?? '',
        advice: j['advice'] ?? '',
        potentialSaving: (j['potential_saving'] ?? 0).toDouble(),
        priority: (j['priority'] ?? 9) as int,
        category: j['category'] ?? 'investment',
      );
}

class RegimeBreakdown {
  final double taxableIncome;
  final double baseTax;
  final double rebate87a;
  final double surcharge;
  final double cess;
  final double incomeTax;
  final double cgTax;
  final double totalTax;
  final double standardDeduction;
  final double hraExemption;
  final double totalDeductions;

  RegimeBreakdown({
    required this.taxableIncome,
    required this.baseTax,
    required this.rebate87a,
    required this.surcharge,
    required this.cess,
    required this.incomeTax,
    required this.cgTax,
    required this.totalTax,
    this.standardDeduction = 0,
    this.hraExemption = 0,
    this.totalDeductions = 0,
  });

  factory RegimeBreakdown.fromJson(Map<String, dynamic> j) => RegimeBreakdown(
        taxableIncome:     (j['taxable_income']     ?? 0).toDouble(),
        baseTax:           (j['base_tax']            ?? 0).toDouble(),
        rebate87a:         (j['rebate_87a']          ?? 0).toDouble(),
        surcharge:         (j['surcharge']           ?? 0).toDouble(),
        cess:              (j['cess']                ?? 0).toDouble(),
        incomeTax:         (j['income_tax']          ?? 0).toDouble(),
        cgTax:             (j['cg_tax']              ?? 0).toDouble(),
        totalTax:          (j['total_tax']           ?? 0).toDouble(),
        standardDeduction: (j['standard_deduction']  ?? 0).toDouble(),
        hraExemption:      (j['hra_exemption']       ?? 0).toDouble(),
        // FIX BUG 5: backend sends 'total_deductions', NOT 'total'
        totalDeductions:   (j['total_deductions'] ?? j['total'] ?? 0).toDouble(),
      );
}

class TaxResultModel {
  final double oldRegimeTax;
  final double newRegimeTax;
  final String bestRegime;
  final double taxableIncome;
  final double taxSavings;
  final List<String> recommendations;
  final List<CaAdviceItem> caAdvice;
  final RegimeBreakdown oldBreakdown;
  final RegimeBreakdown newBreakdown;
  final double grossIncome;

  TaxResultModel({
    required this.oldRegimeTax,
    required this.newRegimeTax,
    required this.bestRegime,
    required this.taxableIncome,
    required this.taxSavings,
    required this.recommendations,
    required this.caAdvice,
    required this.oldBreakdown,
    required this.newBreakdown,
    required this.grossIncome,
  });

  factory TaxResultModel.fromJson(Map<String, dynamic> j) {
    final bd = j['breakdown'] ?? {};
    return TaxResultModel(
      oldRegimeTax: (j['old_regime_tax'] ?? 0).toDouble(),
      newRegimeTax: (j['new_regime_tax'] ?? 0).toDouble(),
      bestRegime: j['best_regime'] ?? 'New',
      taxableIncome: (j['taxable_income'] ?? 0).toDouble(),
      taxSavings: (j['tax_savings'] ?? 0).toDouble(),
      recommendations: List<String>.from(j['recommendations'] ?? []),
      caAdvice: (j['ca_advice'] as List? ?? [])
          .map((e) => CaAdviceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      oldBreakdown: RegimeBreakdown.fromJson(bd['old_regime'] ?? {}),
      newBreakdown: RegimeBreakdown.fromJson(bd['new_regime'] ?? {}),
      grossIncome: (bd['gross_income'] ?? 0).toDouble(),
    );
  }

  double get taxPayable =>
      bestRegime.toLowerCase() == 'old' ? oldRegimeTax : newRegimeTax;
}