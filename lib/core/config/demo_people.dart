/// Identidades ficticias del prototipo. Las fotos ilustrativas se descargan
/// una vez y se incluyen en el build; nunca se buscan personas por sus nombres.
abstract final class DemoPeople {
  static const records =
      <String, ({String photo, String document, String representative})>{
        'demo-admin': (
          photo: 'images/people/demo-admin.jpg',
          document: 'DEMO-EMP-0001',
          representative: '',
        ),
        'demo-employee': (
          photo: 'images/people/demo-employee.jpg',
          document: 'DEMO-EMP-0002',
          representative: '',
        ),
        'demo-history-staff-1-0': (
          photo: 'images/people/demo-history-staff-1-0.jpg',
          document: 'DEMO-EMP-0003',
          representative: '',
        ),
        'demo-history-staff-1-1': (
          photo: 'images/people/demo-history-staff-1-1.jpg',
          document: 'DEMO-EMP-0004',
          representative: '',
        ),
        'demo-history-staff-2-0': (
          photo: 'images/people/demo-history-staff-2-0.jpg',
          document: 'DEMO-EMP-0005',
          representative: '',
        ),
        'demo-history-staff-2-1': (
          photo: 'images/people/demo-history-staff-2-1.jpg',
          document: 'DEMO-EMP-0006',
          representative: '',
        ),
        'demo-history-customer-0': (
          photo: 'images/people/demo-history-customer-0.jpg',
          document: 'DEMO-CLI-0007',
          representative: '',
        ),
        'demo-history-customer-1': (
          photo: 'images/people/demo-history-customer-1.jpg',
          document: 'DEMO-CLI-0008',
          representative: '',
        ),
        'demo-history-customer-2': (
          photo: 'images/people/demo-history-customer-2.jpg',
          document: 'DEMO-CLI-0009',
          representative: '',
        ),
        'demo-history-customer-3': (
          photo: 'images/people/demo-history-customer-3.jpg',
          document: 'DEMO-CLI-0010',
          representative: '',
        ),
        'demo-history-customer-4': (
          photo: 'images/people/demo-history-customer-4.jpg',
          document: 'DEMO-CLI-0011',
          representative: '',
        ),
        'demo-history-customer-5': (
          photo: 'images/people/demo-history-customer-5.jpg',
          document: 'DEMO-CLI-0012',
          representative: '',
        ),
        'demo-history-customer-6': (
          photo: 'images/people/demo-history-customer-6.jpg',
          document: 'DEMO-CLI-0013',
          representative: '',
        ),
        'demo-history-customer-7': (
          photo: 'images/people/demo-history-customer-7.jpg',
          document: 'DEMO-CLI-0014',
          representative: '',
        ),
        'demo-history-customer-8': (
          photo: 'images/people/demo-history-customer-8.jpg',
          document: 'DEMO-CLI-0015',
          representative: '',
        ),
        'demo-history-customer-9': (
          photo: 'images/people/demo-history-customer-9.jpg',
          document: 'DEMO-CLI-0016',
          representative: '',
        ),
        'demo-history-customer-10': (
          photo: 'images/people/demo-history-customer-10.jpg',
          document: 'DEMO-CLI-0017',
          representative: '',
        ),
        'demo-history-customer-11': (
          photo: 'images/people/demo-history-customer-11.jpg',
          document: 'DEMO-CLI-0018',
          representative: '',
        ),
        'demo-history-customer-12': (
          photo: 'images/people/demo-history-customer-12.jpg',
          document: 'DEMO-CLI-0019',
          representative: '',
        ),
        'demo-history-customer-13': (
          photo: 'images/people/demo-history-customer-13.jpg',
          document: 'DEMO-CLI-0020',
          representative: '',
        ),
        'demo-history-customer-14': (
          photo: 'images/people/demo-history-customer-14.jpg',
          document: 'DEMO-CLI-0021',
          representative: '',
        ),
        'demo-history-customer-15': (
          photo: 'images/people/demo-history-customer-15.jpg',
          document: 'DEMO-CLI-0022',
          representative: '',
        ),
        'demo-history-supplier-0': (
          photo: 'images/people/demo-history-supplier-0.jpg',
          document: 'DEMO-PRO-0023',
          representative: 'Elena Gutiérrez',
        ),
        'demo-history-supplier-1': (
          photo: 'images/people/demo-history-supplier-1.jpg',
          document: 'DEMO-PRO-0024',
          representative: 'Roberto Méndez',
        ),
        'demo-history-supplier-2': (
          photo: 'images/people/demo-history-supplier-2.jpg',
          document: 'DEMO-PRO-0025',
          representative: 'Claudia Herrera',
        ),
        'demo-history-supplier-3': (
          photo: 'images/people/demo-history-supplier-3.jpg',
          document: 'DEMO-PRO-0026',
          representative: 'Francisco Molina',
        ),
        'customer-demo': (
          photo: 'images/people/customer-demo.jpg',
          document: 'DEMO-CLI-0027',
          representative: '',
        ),
        'supplier-demo': (
          photo: 'images/people/supplier-demo.jpg',
          document: 'DEMO-PRO-0028',
          representative: 'Elena Gutiérrez',
        ),
      };
  static bool validPhoto(String value) =>
      value.isEmpty || records.values.any((p) => p.photo == value);
}
