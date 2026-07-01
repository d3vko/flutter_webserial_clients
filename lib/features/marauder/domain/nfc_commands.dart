String nfcScanCommand() => 'nfc scan';

String nfcReadCommand() => 'nfc read';

String nfcUrlCommand(String url) => 'nfc -u $url';

String nfcTextCommand(String text) => 'nfc -t "$text"';

String nfcVcardCommand(String name, String phone, String email) =>
    'nfc -v "$name,$phone,$email"';

String nfcWifiCommand(String ssid, String password, String auth) =>
    'nfc -w "$ssid,$password,$auth"';
