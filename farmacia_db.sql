-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE farmacia_jae.empleado (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  nombres character varying NOT NULL,
  apellidos character varying NOT NULL,
  cargo character varying NOT NULL,
  telefono character varying,
  correo character varying,
  activo boolean NOT NULL DEFAULT true,
  fecha_registro timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT empleado_pkey PRIMARY KEY (id)
);
CREATE TABLE farmacia_jae.rol (
  id smallint GENERATED ALWAYS AS IDENTITY NOT NULL,
  nombre character varying NOT NULL UNIQUE,
  descripcion character varying,
  activo boolean NOT NULL DEFAULT true,
  CONSTRAINT rol_pkey PRIMARY KEY (id)
);
CREATE TABLE farmacia_jae.permiso (
  id smallint GENERATED ALWAYS AS IDENTITY NOT NULL,
  codigo character varying NOT NULL UNIQUE,
  descripcion character varying NOT NULL,
  CONSTRAINT permiso_pkey PRIMARY KEY (id)
);
CREATE TABLE farmacia_jae.rol_permiso (
  rol_id smallint NOT NULL,
  permiso_id smallint NOT NULL,
  CONSTRAINT rol_permiso_pkey PRIMARY KEY (rol_id, permiso_id),
  CONSTRAINT rol_permiso_permiso_id_fkey FOREIGN KEY (permiso_id) REFERENCES farmacia_jae.permiso(id),
  CONSTRAINT rol_permiso_rol_id_fkey FOREIGN KEY (rol_id) REFERENCES farmacia_jae.rol(id)
);
CREATE TABLE farmacia_jae.usuario (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  empleado_id bigint UNIQUE,
  rol_id smallint NOT NULL,
  nombre_usuario character varying NOT NULL UNIQUE,
  contrasena_hash text NOT NULL,
  activo boolean NOT NULL DEFAULT true,
  intentos_fallidos smallint NOT NULL DEFAULT 0 CHECK (intentos_fallidos >= 0),
  ultimo_acceso timestamp with time zone,
  creado_en timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT usuario_pkey PRIMARY KEY (id),
  CONSTRAINT usuario_empleado_id_fkey FOREIGN KEY (empleado_id) REFERENCES farmacia_jae.empleado(id),
  CONSTRAINT usuario_rol_id_fkey FOREIGN KEY (rol_id) REFERENCES farmacia_jae.rol(id)
);
CREATE TABLE farmacia_jae.categoria (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  nombre character varying NOT NULL UNIQUE,
  descripcion character varying,
  activa boolean NOT NULL DEFAULT true,
  CONSTRAINT categoria_pkey PRIMARY KEY (id)
);
CREATE TABLE farmacia_jae.proveedor (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  nombre character varying NOT NULL,
  ruc character varying,
  telefono character varying,
  correo character varying,
  direccion character varying,
  activo boolean NOT NULL DEFAULT true,
  creado_en timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT proveedor_pkey PRIMARY KEY (id)
);
CREATE TABLE farmacia_jae.cliente (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  nombre character varying NOT NULL,
  identificacion character varying,
  telefono character varying,
  correo character varying,
  creado_en timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT cliente_pkey PRIMARY KEY (id)
);
CREATE TABLE farmacia_jae.producto (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  categoria_id bigint,
  codigo_barras character varying,
  nombre character varying NOT NULL,
  nombre_generico character varying,
  concentracion character varying,
  presentacion character varying,
  unidad_medida character varying NOT NULL DEFAULT 'unidad'::character varying,
  precio_venta numeric NOT NULL CHECK (precio_venta >= 0::numeric),
  stock_minimo integer NOT NULL DEFAULT 0 CHECK (stock_minimo >= 0),
  stock_maximo integer,
  activo boolean NOT NULL DEFAULT true,
  creado_en timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT producto_pkey PRIMARY KEY (id),
  CONSTRAINT producto_categoria_id_fkey FOREIGN KEY (categoria_id) REFERENCES farmacia_jae.categoria(id)
);
CREATE TABLE farmacia_jae.lote (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  producto_id bigint NOT NULL,
  proveedor_id bigint,
  numero_lote character varying NOT NULL,
  fecha_ingreso date NOT NULL DEFAULT CURRENT_DATE,
  fecha_vencimiento date NOT NULL,
  costo_unitario numeric NOT NULL DEFAULT 0 CHECK (costo_unitario >= 0::numeric),
  cantidad_actual integer NOT NULL DEFAULT 0 CHECK (cantidad_actual >= 0),
  estado character varying NOT NULL DEFAULT 'DISPONIBLE'::character varying CHECK (estado::text = ANY (ARRAY['DISPONIBLE'::character varying, 'INMOVILIZADO'::character varying, 'AGOTADO'::character varying, 'VENCIDO'::character varying]::text[])),
  observacion character varying,
  creado_en timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT lote_pkey PRIMARY KEY (id),
  CONSTRAINT lote_producto_id_fkey FOREIGN KEY (producto_id) REFERENCES farmacia_jae.producto(id),
  CONSTRAINT lote_proveedor_id_fkey FOREIGN KEY (proveedor_id) REFERENCES farmacia_jae.proveedor(id)
);
CREATE TABLE farmacia_jae.movimiento_inventario (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  lote_id bigint NOT NULL,
  tipo character varying NOT NULL CHECK (tipo::text = ANY (ARRAY['ENTRADA_COMPRA'::character varying, 'VENTA'::character varying, 'AJUSTE_POSITIVO'::character varying, 'AJUSTE_NEGATIVO'::character varying, 'DEVOLUCION_CLIENTE'::character varying, 'DEVOLUCION_PROVEEDOR'::character varying, 'MERMA'::character varying, 'ANULACION_VENTA'::character varying]::text[])),
  cantidad integer NOT NULL CHECK (cantidad <> 0),
  stock_resultante integer NOT NULL DEFAULT 0 CHECK (stock_resultante >= 0),
  motivo character varying,
  documento_referencia character varying,
  usuario_id bigint,
  fecha timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT movimiento_inventario_pkey PRIMARY KEY (id),
  CONSTRAINT movimiento_inventario_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES farmacia_jae.lote(id),
  CONSTRAINT movimiento_inventario_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES farmacia_jae.usuario(id)
);
CREATE TABLE farmacia_jae.compra (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  proveedor_id bigint NOT NULL,
  numero_documento character varying,
  fecha timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  usuario_id bigint NOT NULL,
  subtotal numeric NOT NULL DEFAULT 0 CHECK (subtotal >= 0::numeric),
  total numeric NOT NULL DEFAULT 0 CHECK (total >= 0::numeric),
  estado character varying NOT NULL DEFAULT 'RECIBIDA'::character varying CHECK (estado::text = ANY (ARRAY['RECIBIDA'::character varying, 'ANULADA'::character varying]::text[])),
  observacion character varying,
  CONSTRAINT compra_pkey PRIMARY KEY (id),
  CONSTRAINT compra_proveedor_id_fkey FOREIGN KEY (proveedor_id) REFERENCES farmacia_jae.proveedor(id),
  CONSTRAINT compra_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES farmacia_jae.usuario(id)
);
CREATE TABLE farmacia_jae.detalle_compra (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  compra_id bigint NOT NULL,
  lote_id bigint NOT NULL,
  cantidad integer NOT NULL CHECK (cantidad > 0),
  costo_unitario numeric NOT NULL CHECK (costo_unitario >= 0::numeric),
  subtotal numeric DEFAULT (((cantidad)::numeric * costo_unitario))::numeric(14,2),
  CONSTRAINT detalle_compra_pkey PRIMARY KEY (id),
  CONSTRAINT detalle_compra_compra_id_fkey FOREIGN KEY (compra_id) REFERENCES farmacia_jae.compra(id),
  CONSTRAINT detalle_compra_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES farmacia_jae.lote(id)
);
CREATE TABLE farmacia_jae.venta (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  cliente_id bigint,
  usuario_id bigint NOT NULL,
  fecha timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  subtotal numeric NOT NULL DEFAULT 0 CHECK (subtotal >= 0::numeric),
  descuento numeric NOT NULL DEFAULT 0 CHECK (descuento >= 0::numeric),
  total numeric NOT NULL DEFAULT 0 CHECK (total >= 0::numeric),
  estado character varying NOT NULL DEFAULT 'COMPLETADA'::character varying CHECK (estado::text = ANY (ARRAY['COMPLETADA'::character varying, 'ANULADA'::character varying]::text[])),
  motivo_anulacion character varying,
  anulada_en timestamp with time zone,
  anulada_por bigint,
  observacion character varying,
  CONSTRAINT venta_pkey PRIMARY KEY (id),
  CONSTRAINT venta_cliente_id_fkey FOREIGN KEY (cliente_id) REFERENCES farmacia_jae.cliente(id),
  CONSTRAINT venta_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES farmacia_jae.usuario(id),
  CONSTRAINT venta_anulada_por_fkey FOREIGN KEY (anulada_por) REFERENCES farmacia_jae.usuario(id)
);
CREATE TABLE farmacia_jae.detalle_venta (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  venta_id bigint NOT NULL,
  lote_id bigint NOT NULL,
  cantidad integer NOT NULL CHECK (cantidad > 0),
  precio_unitario numeric NOT NULL CHECK (precio_unitario >= 0::numeric),
  descuento numeric NOT NULL DEFAULT 0 CHECK (descuento >= 0::numeric),
  subtotal numeric DEFAULT (GREATEST((0)::numeric, (((cantidad)::numeric * precio_unitario) - descuento)))::numeric(14,2),
  CONSTRAINT detalle_venta_pkey PRIMARY KEY (id),
  CONSTRAINT detalle_venta_venta_id_fkey FOREIGN KEY (venta_id) REFERENCES farmacia_jae.venta(id),
  CONSTRAINT detalle_venta_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES farmacia_jae.lote(id)
);
CREATE TABLE farmacia_jae.metodo_pago (
  id smallint GENERATED ALWAYS AS IDENTITY NOT NULL,
  nombre character varying NOT NULL UNIQUE,
  activo boolean NOT NULL DEFAULT true,
  CONSTRAINT metodo_pago_pkey PRIMARY KEY (id)
);
CREATE TABLE farmacia_jae.pago_venta (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  venta_id bigint NOT NULL,
  metodo_pago_id smallint NOT NULL,
  monto numeric NOT NULL CHECK (monto > 0::numeric),
  referencia character varying,
  fecha timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT pago_venta_pkey PRIMARY KEY (id),
  CONSTRAINT pago_venta_venta_id_fkey FOREIGN KEY (venta_id) REFERENCES farmacia_jae.venta(id),
  CONSTRAINT pago_venta_metodo_pago_id_fkey FOREIGN KEY (metodo_pago_id) REFERENCES farmacia_jae.metodo_pago(id)
);
CREATE TABLE farmacia_jae.caja (
  id smallint GENERATED ALWAYS AS IDENTITY NOT NULL,
  nombre character varying NOT NULL UNIQUE,
  activa boolean NOT NULL DEFAULT true,
  CONSTRAINT caja_pkey PRIMARY KEY (id)
);
CREATE TABLE farmacia_jae.turno_caja (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  caja_id smallint NOT NULL,
  usuario_apertura_id bigint NOT NULL,
  fecha_apertura timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  monto_inicial numeric NOT NULL DEFAULT 0 CHECK (monto_inicial >= 0::numeric),
  usuario_cierre_id bigint,
  fecha_cierre timestamp with time zone,
  monto_sistema numeric,
  monto_real numeric,
  diferencia numeric DEFAULT 
CASE
    WHEN ((monto_sistema IS NULL) OR (monto_real IS NULL)) THEN NULL::numeric
    ELSE (monto_real - monto_sistema)
END,
  estado character varying NOT NULL DEFAULT 'ABIERTO'::character varying CHECK (estado::text = ANY (ARRAY['ABIERTO'::character varying, 'CERRADO'::character varying]::text[])),
  observacion character varying,
  CONSTRAINT turno_caja_pkey PRIMARY KEY (id),
  CONSTRAINT turno_caja_usuario_apertura_id_fkey FOREIGN KEY (usuario_apertura_id) REFERENCES farmacia_jae.usuario(id),
  CONSTRAINT turno_caja_usuario_cierre_id_fkey FOREIGN KEY (usuario_cierre_id) REFERENCES farmacia_jae.usuario(id),
  CONSTRAINT turno_caja_caja_id_fkey FOREIGN KEY (caja_id) REFERENCES farmacia_jae.caja(id)
);
CREATE TABLE farmacia_jae.movimiento_caja (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  turno_caja_id bigint NOT NULL,
  venta_id bigint,
  usuario_id bigint NOT NULL,
  tipo character varying NOT NULL CHECK (tipo::text = ANY (ARRAY['VENTA'::character varying, 'INGRESO'::character varying, 'EGRESO'::character varying, 'DEVOLUCION'::character varying, 'AJUSTE'::character varying]::text[])),
  monto numeric NOT NULL CHECK (monto > 0::numeric),
  concepto character varying NOT NULL,
  fecha timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT movimiento_caja_pkey PRIMARY KEY (id),
  CONSTRAINT movimiento_caja_turno_caja_id_fkey FOREIGN KEY (turno_caja_id) REFERENCES farmacia_jae.turno_caja(id),
  CONSTRAINT movimiento_caja_venta_id_fkey FOREIGN KEY (venta_id) REFERENCES farmacia_jae.venta(id),
  CONSTRAINT movimiento_caja_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES farmacia_jae.usuario(id)
);
CREATE TABLE farmacia_jae.auditoria (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  tabla character varying NOT NULL,
  operacion character varying NOT NULL CHECK (operacion::text = ANY (ARRAY['INSERT'::character varying, 'UPDATE'::character varying, 'DELETE'::character varying]::text[])),
  registro_id character varying,
  usuario_id bigint,
  usuario_bd character varying NOT NULL DEFAULT CURRENT_USER,
  fecha timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  datos_anteriores jsonb,
  datos_nuevos jsonb,
  CONSTRAINT auditoria_pkey PRIMARY KEY (id),
  CONSTRAINT auditoria_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES farmacia_jae.usuario(id)
);
CREATE TABLE farmacia_jae.incidente_ti (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  reportado_por bigint,
  categoria character varying NOT NULL,
  descripcion text NOT NULL,
  prioridad character varying NOT NULL CHECK (prioridad::text = ANY (ARRAY['BAJA'::character varying, 'MEDIA'::character varying, 'ALTA'::character varying, 'CRITICA'::character varying]::text[])),
  estado character varying NOT NULL DEFAULT 'ABIERTO'::character varying CHECK (estado::text = ANY (ARRAY['ABIERTO'::character varying, 'EN_PROCESO'::character varying, 'RESUELTO'::character varying, 'CERRADO'::character varying]::text[])),
  fecha_reporte timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_resolucion timestamp with time zone,
  solucion text,
  CONSTRAINT incidente_ti_pkey PRIMARY KEY (id),
  CONSTRAINT incidente_ti_reportado_por_fkey FOREIGN KEY (reportado_por) REFERENCES farmacia_jae.usuario(id)
);
CREATE TABLE farmacia_jae.registro_respaldo (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  tipo character varying NOT NULL CHECK (tipo::text = ANY (ARRAY['COMPLETO'::character varying, 'INCREMENTAL'::character varying, 'LOGICO'::character varying]::text[])),
  inicio timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fin timestamp with time zone,
  estado character varying NOT NULL CHECK (estado::text = ANY (ARRAY['EN_PROCESO'::character varying, 'EXITOSO'::character varying, 'FALLIDO'::character varying]::text[])),
  ubicacion text,
  detalle text,
  verificado boolean NOT NULL DEFAULT false,
  CONSTRAINT registro_respaldo_pkey PRIMARY KEY (id)
);