import '../../../core/utils/json_value.dart';

enum ContactKind { customer, supplier }

/// Cliente/proveedor local. Se archiva, no se borra el historial relacionado.
class Contact {
  const Contact({
    required this.id,
    required this.kind,
    required this.name,
    this.code = '',
    this.supplierType = '',
    this.origin = '',
    this.description = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.identification = '',
    this.representative = '',
    this.photoAsset = '',
    this.active = true,
  });
  final String id, name, phone, email, address;
  final String code, supplierType, origin, description;
  final String identification, representative, photoAsset;
  final ContactKind kind;
  final bool active;
  Contact copyWith({
    String? name,
    String? code,
    String? supplierType,
    String? origin,
    String? description,
    String? phone,
    String? email,
    String? address,
    String? identification,
    String? representative,
    String? photoAsset,
    bool? active,
  }) => Contact(
    id: id,
    kind: kind,
    name: name ?? this.name,
    code: code ?? this.code,
    supplierType: supplierType ?? this.supplierType,
    origin: origin ?? this.origin,
    description: description ?? this.description,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    address: address ?? this.address,
    identification: identification ?? this.identification,
    representative: representative ?? this.representative,
    photoAsset: photoAsset ?? this.photoAsset,
    active: active ?? this.active,
  );
  Map<String, Object> toJson() => {
    'id': id,
    'kind': kind.name,
    'name': name,
    'code': code,
    'supplierType': supplierType,
    'origin': origin,
    'description': description,
    'phone': phone,
    'email': email,
    'address': address,
    'identification': identification,
    'representative': representative,
    'photoAsset': photoAsset,
    'active': active,
  };
  factory Contact.fromJson(JsonMap j) => Contact(
    id: jsonText(j, 'id'),
    kind: jsonEnum(j, 'kind', ContactKind.values),
    name: jsonText(j, 'name'),
    code: jsonText(j, 'code', fallback: ''),
    supplierType: jsonText(j, 'supplierType', fallback: ''),
    origin: jsonText(j, 'origin', fallback: ''),
    description: jsonText(j, 'description', fallback: ''),
    phone: jsonText(j, 'phone'),
    email: jsonText(j, 'email'),
    address: jsonText(j, 'address'),
    identification: jsonText(j, 'identification', fallback: ''),
    representative: jsonText(j, 'representative', fallback: ''),
    photoAsset: jsonText(j, 'photoAsset', fallback: ''),
    active: jsonBool(j, 'active'),
  );
}
