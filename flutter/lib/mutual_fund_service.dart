import 'dart:convert';
import 'package:http/http.dart' as http;
import 'mutual_fund_page.dart';

class MutualFundService {
  Future<List<MutualFund>> fetchMutualFunds() async {
    final response =
        await http.get(Uri.parse('http://192.168.231.10:5000/mutualfunds'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => MutualFund.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load mutual funds');
    }
  }
}
