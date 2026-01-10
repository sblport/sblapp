class ApiConstants {
  static const String baseUrlTest = 'https://jetty.test';
  static const String baseUrlProd = 'https://sblport.site';
  
  // Use baseUrlProd by default or toggle as needed
  static const String baseUrl = baseUrlProd; // Production deployment
  
  // Auth endpoints
  static const String loginEndpoint = '/api/login';
  static const String changePasswordEndpoint = '/api/change-password';
  static const String workhourEndpoint = '/api/workhour';
  
  // Equipment Operations endpoints
  static const String eqpOperationsEndpoint = '/api/eqp/operations';
  static const String eqpEquipmentEndpoint = '/api/eqp/equipment';
  static const String eqpActivitiesEndpoint = '/api/eqp/activities';
  static const String eqpLocationsEndpoint = '/api/eqp/locations';
  static const String eqpOrgsEndpoint = '/api/eqp/orgs';
}
