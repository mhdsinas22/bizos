abstract class ShortcutPairServiceRemoteDatasource {
  Future<Map<String, dynamic>> pairShortCut({required String deviceName});
  Future<Map<String, dynamic>> verifyPairingCode({required String code});
  Future<Map<String, dynamic>> provisionShortcutToken({
    required String deviceName,
  });
}
