import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Terms & Conditions"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      "Dimple Packaging – Terms & Conditions",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Effective Date: DD/MM/YYYY",
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 20),

                  sectionTitle("1. General"),
                  sectionText(
                      "These Terms and Conditions govern all transactions between Dimple Packaging (“we”) and the Client (“you”). Placing an order with us means you have read, understood, and agreed to these Terms."),

                  sectionTitle("2. Orders & Confirmation"),
                  sectionText(
                      "• All orders must be placed via official Purchase Order (PO), email, or company order form.\n• Once confirmed, orders cannot be altered without written approval.\n• For custom packaging orders, advance payment is required before production."),

                  sectionTitle("3. Prices & Payment"),
                  sectionText(
                      "• Prices are exclusive of GST and applicable taxes unless stated otherwise.\n• Payment Terms – 50% advance, 50% before dispatch (unless specified otherwise).\n• Late payments will attract interest as per company policy."),

                  sectionTitle("4. Production & Delivery"),
                  sectionText(
                      "• Production timelines start after confirmation and advance payment.\n• Delivery dates are estimates and may vary due to external factors.\n• Delivery charges are billed separately unless agreed otherwise."),

                  sectionTitle("5. Quality & Tolerances"),
                  sectionText(
                      "• Products are manufactured to industry standards.\n• Minor variations (±5%) in size, color, or material are acceptable.\n• Custom-made products are non-returnable and non-refundable."),

                  sectionTitle("6. Risk & Ownership"),
                  sectionText(
                      "• Risk passes to the Client upon delivery.\n• Ownership remains with Dimple Packaging until full payment is received."),

                  sectionTitle("7. Claims & Returns"),
                  sectionText(
                      "• Claims regarding damages or shortages must be made within 48 hours of delivery.\n• No returns without prior written consent."),

                  sectionTitle("8. Intellectual Property"),
                  sectionText(
                      "• All designs, concepts, and related intellectual property remain the property of Dimple Packaging."),

                  sectionTitle("9. Limitation of Liability"),
                  sectionText(
                      "• The company is not liable for indirect or consequential damages, including loss of profit."),

                  sectionTitle("10. Governing Law"),
                  sectionText(
                      "• These Terms are governed by Indian law.\n• Disputes are subject to the jurisdiction of courts in [Your City], India."),

                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "Accept & Continue",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 5),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  Widget sectionText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, height: 1.5),
      ),
    );
  }
}
