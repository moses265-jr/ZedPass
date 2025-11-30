import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vpn_provider.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VpnProvider>().requestPermission();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ZedPass'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<VpnProvider>(
        builder: (context, vpnProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusTitle(vpnProvider.status),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                _buildConnectionCard(vpnProvider),
                const SizedBox(height: 16),
                _buildServerCard(vpnProvider),
                const SizedBox(height: 16),
                _buildStatsCard(vpnProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getStatusTitle(VpnStatus status) {
    switch (status) {
      case VpnStatus.connected:
        return 'Your privacy is protected';
      case VpnStatus.connecting:
        return 'Connecting...';
      case VpnStatus.disconnected:
        return 'Not protected';
    }
  }

  Widget _buildConnectionCard(VpnProvider vpnProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildConnectionButton(vpnProvider),
          const SizedBox(height: 24),
          Text(
            vpnProvider.status == VpnStatus.connected
                ? vpnProvider.formatTotalBytes(vpnProvider.totalDownload + vpnProvider.totalUpload)
                : '0 B',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            vpnProvider.status == VpnStatus.connected
                ? 'Internet traffic protected'
                : 'Tap to connect',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          if (vpnProvider.status == VpnStatus.connected) ...[
            const SizedBox(height: 16),
            Text(
              vpnProvider.formatDuration(vpnProvider.connectionDuration),
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildConnectionButton(VpnProvider vpnProvider) {
    Color buttonColor;
    IconData buttonIcon;
    
    switch (vpnProvider.status) {
      case VpnStatus.connected:
        buttonColor = AppTheme.primaryColor;
        buttonIcon = Icons.shield_outlined;
        break;
      case VpnStatus.connecting:
        buttonColor = Colors.orange;
        buttonIcon = Icons.sync;
        break;
      case VpnStatus.disconnected:
        buttonColor = AppTheme.textSecondary;
        buttonIcon = Icons.power_settings_new;
        break;
    }

    Widget buttonContent = Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: buttonColor.withValues(alpha: 0.15),
        border: Border.all(
          color: buttonColor,
          width: 3,
        ),
      ),
      child: Icon(
        buttonIcon,
        size: 48,
        color: buttonColor,
      ),
    );

    if (vpnProvider.status == VpnStatus.connecting) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: buttonContent,
          );
        },
      );
    }

    return GestureDetector(
      onTap: () {
        if (vpnProvider.isConfigured) {
          vpnProvider.toggleConnection();
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please configure server settings first'),
              backgroundColor: AppTheme.cardColor,
            ),
          );
        }
      },
      child: buttonContent,
    );
  }

  Widget _buildServerCard(VpnProvider vpnProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.vpn_lock_outlined,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vpnProvider.isConfigured ? vpnProvider.host : 'Not configured',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  vpnProvider.status == VpnStatus.connected
                      ? 'Connected'
                      : vpnProvider.status == VpnStatus.connecting
                          ? 'Connecting...'
                          : 'Disconnected',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: vpnProvider.status == VpnStatus.connected,
            onChanged: vpnProvider.isConfigured
                ? (value) => vpnProvider.toggleConnection()
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(VpnProvider vpnProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Connection Stats',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  Icons.arrow_downward,
                  'Download',
                  vpnProvider.formatBytes(vpnProvider.downloadSpeed),
                  Colors.green,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: AppTheme.textSecondary.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _buildStatItem(
                  Icons.arrow_upward,
                  'Upload',
                  vpnProvider.formatBytes(vpnProvider.uploadSpeed),
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
