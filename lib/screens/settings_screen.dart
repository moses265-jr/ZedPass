import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vpn_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dnsController = TextEditingController();
  final _proxyHostController = TextEditingController();
  final _proxyPortController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _dnsEnabled = false;
  bool _proxyEnabled = false;
  bool _verifyHostName = false;
  bool _verifySSLCert = false;
  String _sslVersion = 'TLSv1_2';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final vpnProvider = context.read<VpnProvider>();
    _hostController.text = vpnProvider.host;
    _portController.text = vpnProvider.port.toString();
    _usernameController.text = vpnProvider.username;
    _passwordController.text = vpnProvider.password;
    _dnsController.text = vpnProvider.dns;
    _dnsEnabled = vpnProvider.dnsEnabled;
    _proxyHostController.text = vpnProvider.proxyHost;
    _proxyPortController.text = vpnProvider.proxyPort.toString();
    _proxyEnabled = vpnProvider.proxyEnabled;
    _verifyHostName = vpnProvider.verifyHostName;
    _verifySSLCert = vpnProvider.verifySSLCert;
    _sslVersion = vpnProvider.sslVersion;
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _dnsController.dispose();
    _proxyHostController.dispose();
    _proxyPortController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Server Configuration'),
              const SizedBox(height: 16),
              _buildServerSection(),
              const SizedBox(height: 32),
              _buildSectionTitle('DNS Settings'),
              const SizedBox(height: 16),
              _buildDnsSection(),
              const SizedBox(height: 32),
              _buildSectionTitle('Proxy Settings'),
              const SizedBox(height: 16),
              _buildProxySection(),
              const SizedBox(height: 32),
              _buildSectionTitle('Advanced'),
              const SizedBox(height: 16),
              _buildAdvancedSection(),
              const SizedBox(height: 32),
              _buildCertificateSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildServerSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _hostController,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Host',
              hintText: 'vpn.example.com',
              prefixIcon: Icon(Icons.dns_outlined, color: AppTheme.textSecondary),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter host';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _portController,
            style: const TextStyle(color: AppTheme.textPrimary),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Port',
              hintText: '443',
              prefixIcon: Icon(Icons.numbers_outlined, color: AppTheme.textSecondary),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter port';
              }
              if (int.tryParse(value) == null) {
                return 'Please enter valid port';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _usernameController,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Username',
              hintText: 'Enter username',
              prefixIcon: Icon(Icons.person_outline, color: AppTheme.textSecondary),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter username';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            style: const TextStyle(color: AppTheme.textPrimary),
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter password',
              prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textSecondary),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppTheme.textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter password';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDnsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.dns, color: AppTheme.primaryColor),
                  SizedBox(width: 12),
                  Text(
                    'Custom DNS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _dnsEnabled,
                onChanged: (value) {
                  setState(() {
                    _dnsEnabled = value;
                  });
                },
              ),
            ],
          ),
          if (_dnsEnabled) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _dnsController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'DNS Server',
                hintText: '8.8.8.8',
                prefixIcon: Icon(Icons.public_outlined, color: AppTheme.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProxySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.security, color: AppTheme.primaryColor),
                  SizedBox(width: 12),
                  Text(
                    'Proxy',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _proxyEnabled,
                onChanged: (value) {
                  setState(() {
                    _proxyEnabled = value;
                  });
                },
              ),
            ],
          ),
          if (_proxyEnabled) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _proxyHostController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Proxy Host',
                hintText: 'proxy.example.com',
                prefixIcon: Icon(Icons.computer_outlined, color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _proxyPortController,
              style: const TextStyle(color: AppTheme.textPrimary),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Proxy Port',
                hintText: '8080',
                prefixIcon: Icon(Icons.numbers_outlined, color: AppTheme.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvancedSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            icon: Icons.verified_user_outlined,
            title: 'Verify Hostname',
            subtitle: 'Validate server hostname',
            value: _verifyHostName,
            onChanged: (value) {
              setState(() {
                _verifyHostName = value;
              });
            },
          ),
          const Divider(color: AppTheme.surfaceColor, height: 24),
          _buildSwitchTile(
            icon: Icons.security_outlined,
            title: 'Verify SSL Certificate',
            subtitle: 'Validate SSL certificate',
            value: _verifySSLCert,
            onChanged: (value) {
              setState(() {
                _verifySSLCert = value;
              });
            },
          ),
          const Divider(color: AppTheme.surfaceColor, height: 24),
          Row(
            children: [
              const Icon(Icons.lock_clock_outlined, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'SSL Version',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              DropdownButton<String>(
                value: _sslVersion,
                dropdownColor: AppTheme.cardColor,
                style: const TextStyle(color: AppTheme.textPrimary),
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'TLSv1', child: Text('TLS 1.0')),
                  DropdownMenuItem(value: 'TLSv1_1', child: Text('TLS 1.1')),
                  DropdownMenuItem(value: 'TLSv1_2', child: Text('TLS 1.2')),
                  DropdownMenuItem(value: 'TLSv1_3', child: Text('TLS 1.3')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _sslVersion = value;
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  Widget _buildCertificateSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () async {
          final vpnProvider = context.read<VpnProvider>();
          final certPath = await vpnProvider.addCertificate();
          if (certPath != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Certificate added: $certPath'),
                backgroundColor: AppTheme.primaryColor,
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add_card_outlined,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Certificate',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Import custom SSL certificate',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final vpnProvider = context.read<VpnProvider>();
      
      await vpnProvider.saveSettings(
        host: _hostController.text,
        port: int.parse(_portController.text),
        username: _usernameController.text,
        password: _passwordController.text,
      );
      
      await vpnProvider.saveDnsSettings(_dnsController.text, _dnsEnabled);
      
      await vpnProvider.saveProxySettings(
        _proxyHostController.text,
        int.tryParse(_proxyPortController.text) ?? 8080,
        _proxyEnabled,
      );
      
      await vpnProvider.saveAdvancedSettings(
        verifyHostName: _verifyHostName,
        verifySSLCert: _verifySSLCert,
        sslVersion: _sslVersion,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
        Navigator.pop(context);
      }
    }
  }
}
