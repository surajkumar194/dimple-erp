import 'package:dimple_erp/extra.dart/MenuTab.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row
            Row(
              children: [
                const Text(
                  "Finance Year : 2025-26",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    "For GST Help",
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      color: Colors.black,
                    ),
                  ),
                ),
                const Text("For Technical Support : "),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    "info@dimplepackaging.com",
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 1.h),

            // Note & Icons Row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 1.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "Note: Do not use comma(') for apostrophe symbol use hyphen(` ).",
                    style: TextStyle(color: Colors.red, fontSize: 12.sp),
                  ),
                  Icon(Icons.device_hub_outlined, size: 16.sp),
                  SizedBox(width: 0.2.w),
                  Icon(Icons.home, size: 16.sp),
                  SizedBox(width: 0.2.w),
                  Text("Welcome ", style: TextStyle(fontSize: 12.sp)),
                  Text(
                    "suraj",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 12.sp),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, "/login");
                    },
                    child: Text(
                      "LOG OUT",
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w300,
                        decoration: TextDecoration.underline,
                        color: const Color(0xff29166f),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 1.h),

            // Blue Menu Row
            Container(
              color: const Color(0xff6dcff6),
              child: Row(
                children: [
              SizedBox(width: 2.w),

                  MenuTab(
                    title: "Sales",
                    items: {
                      'Masters': [
                        'Customers Master',
                        'General Master-1',
                        'General Master-2',
                        'Sales Person',
                      ],
                      'Transactions': [
                        'Cost Estimation',
                        'Manual Quotation',
                        'RM Projection',
                        'Sales Order',
                        'Sales Enquiry',
                      ],
                      'Reports': [
                        'Order Booking',
                        'Order Booking & Sales(wo)',
                        'Order Booking & Sales(So)',
                      ],
                    },
                  ),
                  SizedBox(width: 2.w),
                  MenuTab(
                    title: "PPC",
                    items: {
                      'Masters': ['Product Master'],
                      'Transactions': [
                        'JDF & BOM',
                        'Production Planning',
                        'Purchase Indent',
                        'Returnable/Job Work Gatepass',
                        'RM Planning',
                      ],
                      'Reports': [
                        'JDF Our Performance Report',
                        'Press Semi Finished',
                        'Process Profit & Loss',
                        'Production Planning Vs Actual',
                        'Wastage Summary Report',
                      ],
                    },
                  ),
                  SizedBox(width: 2.w),
                  MenuTab(
                    title: "Material",
                    items: {
                      'Masters': [
                        'HSN/Accounting Codes',
                        'Ledgers',
                        'Register Setting',
                        'Rm-Group Master',
                        'Rm-Categorcy Master,',
                        'Rm-Item(Goods) Master',
                        'Vendor Master',
                      ],
                      'Transactions': [
                        'FG-Receive Note',
                        'FG-Issue Note',
                        'Purchase Order(Goods)',
                        'Purchase Order(Services)',
                        'RM-Goods Receive Notes',
                        'Rm-Goods Issue Notes',
                      ],
                      'Reports': [
                        'FG-Summary',
                        'FG-Product Ledger',
                        'Rm-Inventory',
                      ],
                      'Fg Under Deviation': ['GRN', 'GIN', 'IN-OUT', 'Summary'],
                    },
                  ),
                  SizedBox(width: 2.w),
                  MenuTab(
                    title: "Operation",
                    items: {
                      'Masters': [
                        'Operator Master',
                        'Tools Library For Offset',
                      ],
                      'Transactions': [
                        'FG Request Slip',
                        'Breakdown Intimation',
                        'Delivery Challan',
                        'Internal Lnk Matching',
                        'Material Reqest Slip',
                      ],
                      'Reports': [
                        'Production Of The Day(with JDF)',
                        'Producitivity Analysis(MC)',
                      ],
                      'Production data Entry': [],
                    },
                  ),
                  SizedBox(width: 2.w),
                  MenuTab(
                    title: "QC/QA",
                    items: {
                      'Masters': [
                        'FG COA Parameters',
                        'Finished Goods Defects',
                        'ISO Document Master',
                        'Process Defect Master',
                        'Process Inspection Parameters',
                        'Rm-Test Group Master',
                        'Shade Card master',
                        'RM-Test Master',
                        'SOP',
                      ],
                      'Transactions': [
                        'Customer Complaint Report',
                        'FG Certificate Of Analysis',
                        'Final Inspection',
                        'Minutes Of Meeting',
                        'Preventive Action Report',
                        'Process Inspection Data Entry',
                        'Quality Test Certificate',
                        'RM-Test Certificate',
                        'Sorting Report',
                        'Vendor Complain Report',
                      ],
                      'Reports': ['Process Inspection of the Day'],
                    },
                  ),
                  SizedBox(width: 2.w),
                  MenuTab(
                    title: "Engineering",
                    items: {
                      'Masters': [
                        'Eng. Record Room',
                        'Preventive Maintenance Check List',
                      ],
                      'Transactions': [
                        'Breakdown Data Entry',
                        'Preventive Maintenance Schedule',
                        'Repairing Getpass',
                      ],
                      'Reports': ['Breakdown History'],
                    },
                  ),
                  SizedBox(width: 2.w),
                  MenuTab(
                    title: "Finance",

                    items: {
                      'Masters': [
                        'Bank Details Master',
                        'Lut Bond',
                        'Ledgers',
                        'Other Invoice Item',
                        'Voucher Type',
                      ],
                      'Transactions': ['Purchase', 'Sales'],
                      'Reports': ['Purchase Register', 'Sales Register'],
                    },
                  ),
                  SizedBox(width: 2.w),
                  MenuTab(
                    title: "Admin",
                    items: {
                      'Users': ['Add User'],
                      'Company Profile': ['Edit Profile'],
                      'Change Password': [],
                      'Terms & Conditions': [],
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
