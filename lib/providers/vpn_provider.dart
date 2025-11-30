import 'package:flutter/material.dart';
import 'package:sstp_flutter/sstp_flutter.dart';
import 'package:sstp_flutter/server.dart';
import 'package:sstp_flutter/android_configuration_sstp.dart';
import 'package:sstp_flutter/ios_configuration_sstp.dart';
import 'package:sstp_flutter/traffic.dart';
import 'package:sstp_flutter/ssl_versions.dart';
import 'package:sstp_flutter/proxy.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum VpnStatus {
  disconnected,
  connecting,
  connected,
}

class VpnProvider extends ChangeNotifier {
  final SstpFlutter _sstpFlutter = SstpFlutter();
  
  VpnStatus _status = VpnStatus.disconnected;
  String _host = '';
  int _port = 443;
  String _username = '';
  String _password = '';
  Duration _connectionDuration = Duration.zero;
  int _downloadSpeed = 0;
  int _uploadSpeed = 0;
  int _totalDownload = 0;
  int _totalUpload = 0;
  String _dns = '';
  bool _dnsEnabled = false;
  String _proxyHost = '';
  int _proxyPort = 0;
  bool _proxyEnabled = false;
  bool _verifyHostName = false;
  bool _verifySSLCert = false;
  String _sslVersion = 'TLSv1_2';

  VpnStatus get status => _status;
  String get host => _host;
  int get port => _port;
  String get username => _username;
  String get password => _password;
  Duration get connectionDuration => _connectionDuration;
  int get downloadSpeed => _downloadSpeed;
  int get uploadSpeed => _uploadSpeed;
  int get totalDownload => _totalDownload;
  int get totalUpload => _totalUpload;
  String get dns => _dns;
  bool get dnsEnabled => _dnsEnabled;
  String get proxyHost => _proxyHost;
  int get proxyPort => _proxyPort;
  bool get proxyEnabled => _proxyEnabled;
  bool get verifyHostName => _verifyHostName;
  bool get verifySSLCert => _verifySSLCert;
  String get sslVersion => _sslVersion;
  bool get isConfigured => _host.isNotEmpty && _username.isNotEmpty && _password.isNotEmpty;

  VpnProvider() {
    _initializeListener();
    _loadSettings();
  }

  void _initializeListener() {
    _sstpFlutter.onResult(
      onConnectedResult: (ConnectionTraffic traffic, Duration duration) {
        _status = VpnStatus.connected;
        _connectionDuration = duration;
        _downloadSpeed = traffic.downloadTraffic ?? 0;
        _uploadSpeed = traffic.uploadTraffic ?? 0;
        _totalDownload += _downloadSpeed;
        _totalUpload += _uploadSpeed;
        notifyListeners();
      },
      onConnectingResult: () {
        _status = VpnStatus.connecting;
        notifyListeners();
      },
      onDisconnectedResult: () {
        _status = VpnStatus.disconnected;
        _downloadSpeed = 0;
        _uploadSpeed = 0;
        _connectionDuration = Duration.zero;
        notifyListeners();
      },
      onError: () {
        _status = VpnStatus.disconnected;
        notifyListeners();
      },
    );
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _host = prefs.getString('vpn_host') ?? '';
    _port = prefs.getInt('vpn_port') ?? 443;
    _username = prefs.getString('vpn_username') ?? '';
    _password = prefs.getString('vpn_password') ?? '';
    _dns = prefs.getString('vpn_dns') ?? '8.8.8.8';
    _dnsEnabled = prefs.getBool('vpn_dns_enabled') ?? false;
    _proxyHost = prefs.getString('vpn_proxy_host') ?? '';
    _proxyPort = prefs.getInt('vpn_proxy_port') ?? 8080;
    _proxyEnabled = prefs.getBool('vpn_proxy_enabled') ?? false;
    _verifyHostName = prefs.getBool('vpn_verify_hostname') ?? false;
    _verifySSLCert = prefs.getBool('vpn_verify_ssl') ?? false;
    _sslVersion = prefs.getString('vpn_ssl_version') ?? 'TLSv1_2';
    notifyListeners();
  }

  Future<void> saveSettings({
    required String host,
    required int port,
    required String username,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    _host = host;
    _port = port;
    _username = username;
    _password = password;
    await prefs.setString('vpn_host', host);
    await prefs.setInt('vpn_port', port);
    await prefs.setString('vpn_username', username);
    await prefs.setString('vpn_password', password);
    notifyListeners();
  }

  Future<void> saveDnsSettings(String dns, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    _dns = dns;
    _dnsEnabled = enabled;
    await prefs.setString('vpn_dns', dns);
    await prefs.setBool('vpn_dns_enabled', enabled);
    notifyListeners();
  }

  Future<void> saveProxySettings(String host, int port, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    _proxyHost = host;
    _proxyPort = port;
    _proxyEnabled = enabled;
    await prefs.setString('vpn_proxy_host', host);
    await prefs.setInt('vpn_proxy_port', port);
    await prefs.setBool('vpn_proxy_enabled', enabled);
    notifyListeners();
  }

  Future<void> saveAdvancedSettings({
    required bool verifyHostName,
    required bool verifySSLCert,
    required String sslVersion,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    _verifyHostName = verifyHostName;
    _verifySSLCert = verifySSLCert;
    _sslVersion = sslVersion;
    await prefs.setBool('vpn_verify_hostname', verifyHostName);
    await prefs.setBool('vpn_verify_ssl', verifySSLCert);
    await prefs.setString('vpn_ssl_version', sslVersion);
    notifyListeners();
  }

  String _getSSLVersion() {
    switch (_sslVersion) {
      case 'TLSv1':
        return SSLVersions.TLSv1;
      case 'TLSv1_1':
        return SSLVersions.TLSv1_1;
      case 'TLSv1_2':
        return SSLVersions.TLsv1_2;
      case 'TLSv1_3':
        return SSLVersions.TLsv1_3;
      default:
        return SSLVersions.DEFAULT;
    }
  }

  Future<bool> requestPermission() async {
    try {
      await _sstpFlutter.takePermission();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> connect() async {
    if (!isConfigured) return;
    
    try {
      _status = VpnStatus.connecting;
      notifyListeners();

      SSTPServer server = SSTPServer(
        host: _host,
        port: _port,
        username: _username,
        password: _password,
        androidConfiguration: SSTPAndroidConfiguration(
          verifyHostName: _verifyHostName,
          useTrustedCert: false,
          verifySSLCert: _verifySSLCert,
          sslVersion: _getSSLVersion(),
          showDisconnectOnNotification: true,
          notificationText: "ZedPass VPN Connected",
        ),
        iosConfiguration: SSTPIOSConfiguration(
          enableMSCHAP2: true,
          enableCHAP: false,
          enablePAP: false,
          enableTLS: false,
        ),
      );

      await _sstpFlutter.saveServerData(server: server);

      if (_dnsEnabled && _dns.isNotEmpty) {
        await _sstpFlutter.enableDns(dns: _dns);
      }

      if (_proxyEnabled && _proxyHost.isNotEmpty) {
        await _sstpFlutter.enableProxy(
          proxy: SSTPProxy(
            ip: _proxyHost,
            port: _proxyPort.toString(),
          ),
        );
      }

      await _sstpFlutter.connectVpn();
    } catch (e) {
      _status = VpnStatus.disconnected;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    try {
      await _sstpFlutter.disconnect();
      if (_dnsEnabled) {
        await _sstpFlutter.disableDNS();
      }
      if (_proxyEnabled) {
        await _sstpFlutter.disableProxy();
      }
      _status = VpnStatus.disconnected;
      _totalDownload = 0;
      _totalUpload = 0;
      notifyListeners();
    } catch (e) {
      _status = VpnStatus.disconnected;
      notifyListeners();
    }
  }

  Future<void> toggleConnection() async {
    if (_status == VpnStatus.connected || _status == VpnStatus.connecting) {
      await disconnect();
    } else {
      await connect();
    }
  }

  Future<String?> checkLastConnectionStatus() async {
    try {
      final status = await _sstpFlutter.checkLastConnectionStatus();
      return status.toString();
    } catch (e) {
      return null;
    }
  }

  Future<String?> addCertificate() async {
    try {
      return await _sstpFlutter.addCertificate();
    } catch (e) {
      return null;
    }
  }

  String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B/s';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB/s';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB/s';
  }

  String formatTotalBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }
}
