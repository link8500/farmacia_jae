/// Las pruebas/nativo no abren el navegador ni producen archivos por accidente.
bool downloadText(
  String name,
  String content, {
  String type = 'text/plain;charset=utf-8',
}) => false;
Future<String?> selectBackupFile() async => null;
bool printDocument(String html) => false;
