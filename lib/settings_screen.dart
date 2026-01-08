import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'setup_screen.dart'; 

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = "v${info.version} (${info.buildNumber})";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- Section 1: General ---
            _buildSection(
              title: "General",
              children: [
                _buildSettingsTile(
                  context,
                  icon: Icons.storefront,
                  title: "Business Profile",
                  subtitle: "Edit logo, signature, and branding",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SetupScreen()),
                    );
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 20),

            // --- Section 2: Legal ---
            _buildSection(
              title: "Legal",
              children: [
                _buildSettingsTile(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  title: "Privacy Policy",
                  onTap: () => _showLegalDialog(context, "Privacy Policy", _privacyPolicyText),
                ),
                _buildDivider(),
                _buildSettingsTile(
                  context,
                  icon: Icons.description_outlined,
                  title: "Terms & Conditions",
                  onTap: () => _showLegalDialog(context, "Terms & Conditions", _termsText),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- Section 3: About ---
            _buildSection(
              title: "About",
              children: [
                _buildSettingsTile(
                  context,
                  icon: Icons.info_outline,
                  title: "App Version",
                  trailing: Text(_appVersion, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                _buildDivider(),
                _buildSettingsTile(
                  context,
                  icon: Icons.code,
                  title: "Developed By",
                  trailing: const Text("Nexora Creative Solutions", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // Branding Footer
            Center(
              child: Column(
                children: [
                  Icon(Icons.diamond_outlined, size: 40, color: Colors.blue.shade200),
                  const SizedBox(height: 10),
                  Text("Invoice Gem", style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- Helpers ---

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 10),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(BuildContext context, {
    required IconData icon, 
    required String title, 
    String? subtitle, 
    Widget? trailing,
    VoidCallback? onTap
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.blue[800], size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 60, endIndent: 20, color: Colors.grey[200]);
  }

  void _showLegalDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Divider(height: 1, color: Colors.grey[300]),
            Container(
              height: 300, 
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Text(content, style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87)),
              ),
            ),
            Divider(height: 1, color: Colors.grey[300]),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.all(15),
                child: Text("Close", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- Legal Text Data ---
  final String _privacyPolicyText = """
**Privacy Policy for Invoice Gem**

1. **Data Collection**: We do not collect any personal data on our servers. All data (invoices, clients, logos) is stored locally on your device.
2. **Permissions**: We require Camera/Gallery access to upload your logo and Biometric access to secure the app.
3. **Third Parties**: No data is shared with third parties unless you explicitly export/share an invoice via email/messaging apps.
4. **Security**: We use local encryption and biometric locks to protect your data, but you are responsible for your device's security.

Contact: info.nexoracreatives.co.ke
""";

  final String _termsText = """
**Terms & Conditions**

1. **Usage**: This app is provided "as is" for business invoicing purposes.
2. **Liability**: Nexora Creative Solutions is not responsible for any financial discrepancies or data loss. Please back up your data using the Export feature.
3. **Ownership**: You retain ownership of all data you generate.
""";
}