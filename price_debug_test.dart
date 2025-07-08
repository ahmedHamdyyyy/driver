import 'dart:convert';
import 'package:http/http.dart' as http;

// Test script to debug price calculation issues
void main() async {
  await testPriceCalculation();
}

Future<void> testPriceCalculation() async {
  print("🔍 Starting price calculation debug test...");

  // Test 1: Check API connectivity
  await testApiConnectivity();

  // Test 2: Test price parsing logic
  testPriceParsingLogic();

  // Test 3: Test currency formatting
  testCurrencyFormatting();
}

Future<void> testApiConnectivity() async {
  print("\n📡 Testing API connectivity...");

  const String baseUrl = 'https://masark-sa.com/api';

  try {
    // Test a simple API endpoint
    final response = await http.get(
      Uri.parse('$baseUrl/appsetting'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    print("✅ API Status Code: ${response.statusCode}");
    print("📊 API Response: ${response.body.substring(0, 200)}...");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print("✅ API is responding correctly");

      // Check if currency settings are in the response
      if (data['data'] != null) {
        print(
            "💰 Currency settings from API: ${data['data']['currency_code'] ?? 'Not found'}");
      }
    } else {
      print("❌ API returned error status: ${response.statusCode}");
    }
  } catch (e) {
    print("❌ API connectivity error: $e");
  }
}

void testPriceParsingLogic() {
  print("\n🧮 Testing price parsing logic...");

  // Test different price data scenarios
  List<Map<String, dynamic>> testCases = [
    // Case 1: Normal price data
    {
      'estimated_price': [
        {
          'total_amount': '25.50',
          'base_fare': '10.00',
          'per_distance_charge': '15.50',
          'distance': '5.2',
          'distance_unit': 'km'
        }
      ]
    },

    // Case 2: Zero price data
    {
      'estimated_price': [
        {
          'total_amount': '0.00',
          'base_fare': '0.00',
          'per_distance_charge': '0.00',
          'distance': '0.0',
          'distance_unit': 'km'
        }
      ]
    },

    // Case 3: Null price data
    {
      'estimated_price': [
        {
          'total_amount': null,
          'base_fare': null,
          'per_distance_charge': null,
          'distance': null,
          'distance_unit': 'km'
        }
      ]
    },

    // Case 4: Empty estimated_price
    {'estimated_price': []},

    // Case 5: No estimated_price field
    {}
  ];

  for (int i = 0; i < testCases.length; i++) {
    print("\n📋 Test Case ${i + 1}:");
    var data = testCases[i];

    num? estimatedTotalPrice;
    num? estimatedDistance;

    if (data['estimated_price'] != null &&
        (data['estimated_price'] as List).isNotEmpty) {
      try {
        var priceData = data['estimated_price'][0];
        estimatedTotalPrice =
            num.tryParse(priceData['total_amount']?.toString() ?? '0');
        estimatedDistance =
            num.tryParse(priceData['distance']?.toString() ?? '0');

        print("  💰 Parsed Price: $estimatedTotalPrice");
        print("  📏 Parsed Distance: $estimatedDistance");

        // Apply the improved logic
        if (estimatedTotalPrice == null || estimatedTotalPrice == 0) {
          print(
              "  ⚠️ Price is null or zero, trying alternative calculation...");

          if (priceData['base_fare'] != null) {
            num baseFare =
                num.tryParse(priceData['base_fare']?.toString() ?? '0') ?? 0;
            num distanceCharge = num.tryParse(
                    priceData['per_distance_charge']?.toString() ?? '0') ??
                0;

            estimatedTotalPrice = baseFare + distanceCharge;
            print(
                "  🔧 Calculated Price: $estimatedTotalPrice (Base: $baseFare + Distance: $distanceCharge)");
          }

          if (estimatedTotalPrice == null || estimatedTotalPrice == 0) {
            estimatedTotalPrice = 10; // Default minimum fare
            print("  🛠️ Using default price: $estimatedTotalPrice");
          }
        }

        print("  ✅ Final Price: $estimatedTotalPrice SAR");
      } catch (e) {
        print("  ❌ Error parsing: $e");
      }
    } else {
      print("  ⚠️ No price data available");
      estimatedTotalPrice = 10; // Default
      print("  🛠️ Using default price: $estimatedTotalPrice SAR");
    }
  }
}

void testCurrencyFormatting() {
  print("\n💱 Testing currency formatting...");

  List<num> testAmounts = [0, 0.00, 10.5, 25.75, 100, 1000.99];

  for (num amount in testAmounts) {
    String formattedAmount = amount.toStringAsFixed(2);
    String displayAmount = formattedAmount;

    if (formattedAmount == "0.00" ||
        formattedAmount.isEmpty ||
        formattedAmount == "0") {
      displayAmount = "10.00"; // Default minimum fare
      print("  ⚠️ Amount $amount -> Default: $displayAmount ر.س");
    } else {
      print("  ✅ Amount $amount -> Display: $displayAmount ر.س");
    }
  }
}
