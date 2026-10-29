class ApiConfig {
  ApiConfig._();

  // AUTENTICACIÓN

  static const String authLocalUrl = 'https://gymflow-auth-local.onrender.com';

  static const String authGoogleUrl =
      'https://gymflow-auth-google.onrender.com';

  // CLIENTES

  static const String clienteAltaUrl =
      'https://gymflow-cliente-alta.onrender.com';

  static const String usuarioConsultaUrl =
      'https://gymflow-usuario-consulta.onrender.com';

  // ASISTENCIAS Y PAGOS

  static const String asistenciasUrl = '$clienteAltaUrl/api/asistencias';

  static const String pagosUrl = '$clienteAltaUrl/api/pagos';

  // RUTINAS Y PROGRESO

  static const String rutinaServiceUrl =
      'https://gymflow-rutina-service.onrender.com';

  // SPRINT 7 - ADMINISTRACIÓN
  // SPRINT 8 - NOTIFICACIONES

  static const String adminApiUrl = 'https://projectgym-5hpt.onrender.com';

  static const String adminDashboardUrl = '$adminApiUrl/api/admin/dashboard';

  static const String adminClientesUrl = '$adminApiUrl/api/admin/clientes';

  static const String adminPersonalUrl = '$adminApiUrl/api/admin/personal';

  static const String notificacionesUrl = '$adminApiUrl/api/notificaciones';

  // GOOGLE LOGIN

  static const String googleClientId =
      '403800585371-gvse8f49bhq6gqh1tmvmk1t8sebg6rvs.apps.googleusercontent.com';
}
