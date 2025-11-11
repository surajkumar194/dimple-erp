import 'package:flutter/material.dart';

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _formKey = GlobalKey<FormState>();

  String? userType;
  String? gender;
  final userTypes = ['Admin', 'Employee'];
  final genders = ['Male', 'Female', 'Other'];

  String? selectedCountry;
  String? selectedState;

 final Map<String, List<String>> countryStates = {
  'India': [
    // 🌟 States (28)
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar',
    'Chhattisgarh', 'Goa', 'Gujarat', 'Haryana',
    'Himachal Pradesh', 'Jharkhand', 'Karnataka', 'Kerala',
    'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya',
    'Mizoram', 'Nagaland', 'Odisha', 'Punjab', 'Rajasthan',
    'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura',
    'Uttar Pradesh', 'Uttarakhand', 'West Bengal',

    // 🏛 Union Territories (8)
    'Andaman and Nicobar Islands', 'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi (NCT)', 'Jammu and Kashmir', 'Ladakh',
    'Lakshadweep', 'Puducherry'
  ],

  'USA': [
    'California', 'Texas', 'Florida', 'New York', 'Illinois',
    'Pennsylvania', 'Ohio', 'Georgia', 'North Carolina', 'Michigan',
    'Virginia', 'Washington', 'Arizona', 'Massachusetts', 'Tennessee'
  ],

  'Canada': [
    'Ontario', 'Quebec', 'British Columbia', 'Alberta', 'Manitoba',
    'Saskatchewan', 'Nova Scotia', 'New Brunswick', 'Newfoundland and Labrador',
    'Prince Edward Island', 'Northwest Territories', 'Yukon', 'Nunavut'
  ],

  'United Kingdom': [
    'England', 'Scotland', 'Wales', 'Northern Ireland'
  ],

  'Australia': [
    'New South Wales', 'Victoria', 'Queensland', 'Western Australia',
    'South Australia', 'Tasmania', 'Australian Capital Territory',
    'Northern Territory'
  ],

  'United Arab Emirates': [
    'Abu Dhabi', 'Dubai', 'Sharjah', 'Ajman', 'Fujairah', 'Ras Al Khaimah', 'Umm Al Quwain'
  ],

  'South Africa': [
    'Eastern Cape', 'Free State', 'Gauteng', 'KwaZulu-Natal',
    'Limpopo', 'Mpumalanga', 'North West', 'Northern Cape', 'Western Cape'
  ],

  'China': [
    'Beijing', 'Shanghai', 'Tianjin', 'Chongqing', 'Guangdong', 'Sichuan', 'Zhejiang',
    'Jiangsu', 'Shandong', 'Henan', 'Hebei', 'Hunan', 'Anhui', 'Fujian', 'Hubei'
  ],

  'Japan': [
    'Tokyo', 'Osaka', 'Kyoto', 'Hokkaido', 'Fukuoka', 'Okinawa', 'Hiroshima', 'Aichi'
  ]
};


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add User"),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      backgroundColor: Colors.grey[200],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.purple.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  dropdownField('Type of User', userTypes, userType, (val) => setState(() => userType = val)),
                  const SizedBox(height: 16),
                  textField('Middle Name'),
                  const SizedBox(height: 16),
                  textField('Last Name'),
                  const SizedBox(height: 16),
                  textField('Birth Date'),
                  const SizedBox(height: 16),
                  genderField(),
                  const SizedBox(height: 16),
                  textField('Designation'),
                  const SizedBox(height: 16),
                  imagePickerField('Image'),
                  const SizedBox(height: 16),
                  imagePickerField('User Signature (Max 30kb)'),
                  const SizedBox(height: 16),
                  textField('Contact No.'),
                  const SizedBox(height: 16),
                  textField('Email'),
                  const SizedBox(height: 16),
                  dropdownField('Country', countryStates.keys.toList(), selectedCountry, (val) {
                    setState(() {
                      selectedCountry = val;
                      selectedState = null;
                    });
                  }),
                  const SizedBox(height: 16),
                  dropdownField(
                    'State',
                    selectedCountry != null ? countryStates[selectedCountry!] ?? [] : [],
                    selectedState,
                    (val) => setState(() => selectedState = val),
                  ),
                  const SizedBox(height: 16),
                  textField('City'),
                  const SizedBox(height: 16),
                  textField('Pincode'),
                  const SizedBox(height: 16),
                  textField('Address', maxLines: 3),
                  const SizedBox(height: 16),
                  textField('Username'),
                  const SizedBox(height: 16),
                  textField('Password'),
                  const SizedBox(height: 16),
                  textField('Confirm Password'),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.deepPurple, Colors.purpleAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: const Text('Register'),
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

  Widget textField(String label, {int maxLines = 1}) => TextFormField(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.deepPurple),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        maxLines: maxLines,
      );

  Widget dropdownField(String label, List<String> items, String? value, void Function(String?) onChanged) =>
      DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.deepPurple),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        value: value,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      );

  Widget genderField() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gender', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          Row(
            children: genders.map((g) {
              return Expanded(
                child: RadioListTile(
                  activeColor: Colors.deepPurple,
                  title: Text(g),
                  value: g,
                  groupValue: gender,
                  onChanged: (val) => setState(() => gender = val),
                ),
              );
            }).toList(),
          )
        ],
      );

  Widget imagePickerField(String label) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.deepPurple)),
          const SizedBox(height: 8),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.purple),
              borderRadius: BorderRadius.circular(8),
              color: Colors.purple.shade50,
              image: const DecorationImage(
                image: AssetImage('assets/placeholder.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: const Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.camera_alt, color: Colors.deepPurple),
              ),
            ),
          ),
        ],
      );
}
