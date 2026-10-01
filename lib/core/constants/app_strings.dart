/// Textos de la app centralizados.
/// Facilitan traducciones futuras (i18n).
class AppStrings {
  AppStrings._();

  // ---------- APP ----------
  static const String appName = 'El Torneo del Cancelado';
  static const String appNameShort = 'Torneo del Cancelado';
  static const String appTagline = 'Una estrella cada vez que dicen algo';

  // ---------- HOME ----------
  static const String homeTitle = 'EL TORNEO\nDEL CANCELADO';
  static const String addMember = 'Agregar Integrante';
  static const String addMemberHint = 'Nombre del concursante';
  static const String noMembers =
      'Aún no hay integrantes.\n¡Agrega el primero!';
  static const String noStars = '— sin estrellas —';
  static const String members = 'Integrantes';

  // ---------- BOTONES ----------
  static const String addStar = '+1 ESTRELLA';
  static const String cancel = 'Cancelar';
  static const String save = 'Guardar';
  static const String delete = 'Eliminar';
  static const String confirm = 'Confirmar';
  static const String close = 'Cerrar';

  // ---------- DETALLE ----------
  static const String today = 'Hoy';
  static const String thisWeek = 'Esta semana';
  static const String thisMonth = 'Este mes';
  static const String total = 'Total';
  static const String history = 'Historial';
  static const String noHistory = 'Todavía no hay estrellas registradas';

  // ---------- RANKING ----------
  static const String ranking = 'Ranking';
  static const String daily = 'Diario';
  static const String weekly = 'Semanal';
  static const String monthly = 'Mensual';
  static const String monthlyWinner = 'GANADOR DEL MES';
  static const String noWinnerYet = 'Aún no hay ganador este mes';

  // ---------- ERRORES ----------
  static const String errorGeneric = 'Algo salió mal';
  static const String errorDatabase = 'Error al acceder a la base de datos';
  static const String errorMemberNotFound = 'Integrante no encontrado';
  static const String errorEmptyName = 'El nombre no puede estar vacío';
  static const String errorDuplicateName =
      'Ya existe un integrante con ese nombre';

  // ---------- CONFIRMACIONES ----------
  static const String deleteMemberTitle = '¿Eliminar integrante?';
  static const String deleteMemberBody =
      'Se borrarán también todas sus estrellas. Esta acción no se puede deshacer.';

  // ---------- FORMATEO DE FECHAS ----------
  static const String dateFormatFull = "d 'de' MMMM 'de' yyyy";
  static const String dateFormatShort = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM HH:mm';
}
