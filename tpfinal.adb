with Text_IO; use Text_IO;
with Ada.Text_IO,
     Ada.Strings.Unbounded,
     Ada.Text_IO.Unbounded_IO,
     Ada.Integer_Text_IO,
     Ada.Float_Text_IO;
use Ada.Text_IO,
    Ada.Strings.Unbounded,
    Ada.Text_IO.Unbounded_IO,
    Ada.Integer_Text_IO,
    Ada.Float_Text_IO;

with utiles; use utiles;
with lista;
with pila;
with arbol;
with fechas; use fechas;

procedure tpfinal is

   --TIPOS

   --ESTRUCTURAS VARIAS

   type tDimensiones is record  --dimensiones de vivienda
      alto: float;
      largo: float;
      profundidad: float;
   end record;

   --Estructura - Listado de productos
   type tinfoProductoAlias is record
      nombre: Unbounded_String;
      especie: Unbounded_String;
      tamaño: Unbounded_String;
      marca: Unbounded_String;
      modelo: Unbounded_String;
      peso: float;
      esVivienda:boolean;
      esTechada:boolean;
      dimensiones:tDimensiones;
      precio: float;
      stock: integer;
      vendidos:integer;
      importeVendido:float;
   end record;
   subtype tClaveProducto is Unbounded_String;     --código alfanumérico
   subtype tinfoProducto is tinfoProductoAlias;
   package tListaProductos is new  lista(tClaveProducto,tinfoProducto,"<","=");  --listado de productos


   --Estructura - Registro de ventas
   subtype tClaveItem is Unbounded_String;
   subtype tInfoItem is integer; --cantidad
   package tListaDetalle is new lista(tClaveItem,tInfoItem,"<","=");
   use tListaDetalle;

   type tInfoFacturaAlias is record
      fecha:tFecha;
      detalle: tListaDetalle.tipoLista;
      subtotal:float;
      descuento:float;
      total: float;
   end record;




   subtype tClaveFactura is integer; --número de factura
   subtype tInfoFactura is tInfoFacturaAlias;
   package tListaFacturas is new lista(tClaveFactura,tInfoFactura,"<","=");
   type tMasVendidos is array (1..10) of tInfoProducto;

   --Estructura - Listado de clientes
   type tInfoClienteAlias is record
      nombre : Unbounded_String;
      apellido: Unbounded_String;
      direccion: Unbounded_String;
      fechaNac: tFecha;
      facturas: tListaFacturas.tipoLista;
   end record;

   subtype tClaveCliente is integer;  --DNI
   subtype tInfoCliente is tInfoClienteAlias;
   package tArbolClientes is new Arbol(tClaveCliente,tInfoCliente,"<","=");

   -- Estructura Alquiler de Jaulas
   type tInfoJaulaAlias is record
      tamanio: Unbounded_String;
      especie: Unbounded_String;
      ocupada: Boolean;
      fechaSalida: tFecha;
   end record;
   subtype tClaveJaula is Integer;
   subtype tInfoJaula is tInfoJaulaAlias;
   package tListaJaulas is new lista(tClaveJaula,tInfoJaula,"<","=");

   type tInfoAlquilerAlias is record
      numJaula: Integer;
      fechaIngreso: tFecha;
      fechaSalida: tFecha;
      precio: Float;
      descuento: Float;
   end record;
   subtype tClaveAlquileres is Integer;
   subtype tInfoAlquiler is tInfoAlquilerAlias;
   package tArbolAlquileresJaulas is new arbol(tClaveAlquileres,tInfoAlquiler,"<","=");



   use tListaProductos;
   use tListaFacturas;
   use tListaJaulas;
   use tArbolClientes; use tArbolClientes.ColaRecorridos;
   use tArbolAlquileresJaulas; use tArbolAlquileresJaulas.ColaRecorridos;

   facturasNoBorradas:exception;

   ------------------NIVEL 5----------------------------

   procedure mostrarItem( listaProductos:in tListaProductos.tipoLista; codBarra:in tClaveProducto; item:in tInfoItem)  is
      --que hace: muestra el nombre, las unidades y el precio de un ítem de una factura
      --precondiciones: listaProductos = L y L es el listado de productos del local, codBarra = K y K es el código de barras que identifica el producto del ítem, unidades = U y U es la cantidad de unidades del producto del ítem
      --poscondiciones:
      --excepciones:--

      producto:tInfoProducto;
   begin
      recuClave(listaProductos,codBarra,producto);
      Put(producto.nombre & " X "& integer'image(item) & " = $" ); Put(producto.precio*float(item),7,2,0);Put_Line("");
   exception
      when tListaProductos.claveNoExiste =>
         Put_Line("El producto fue borrado, su código fue,: " & codBarra &", el valor del item de todas maneras esta sumado en la factura");
   end;

   ------------------NIVEL 4----------------------------
   procedure mostrarPieListadoFacturas( cantidadProductos:in integer; totalVentas:in float; totalDescuento:in float)is
      --que hace: Muestra el pie del listado de una factura
      --precondiciones: cantidadProductos = CP,  totalVentas = T, totalDescuentos = D
      --poscondiciones:
      --excepciones:-
   begin
      Put_Line(integer'Image(cantidadProductos) & " productos comprados");
      Put("El total Gastado es: = $" ); Put(totalVentas,7,2,0);Put_Line("");
      Put("El descuento es de: = $" ); Put(totalDescuento,7,2,0);Put_Line("");
   end;



   procedure listarDetalle ( listaProductos:in tListaProductos.tipoLista; listaDetalle:in tInfoFactura; cantidadProductos:in out Integer) is
      --que hace: Muestra la información de la lista detalles del cliente
      --precondiciones: listaProductos = LP, listaDetalle = LD, cantidadProductos = CP
      --poscondiciones: cantidadProductos = CP° y CP° es CP + n items
      --excepciones:-

      codBarra:tClaveProducto;
      item:tInfoItem;
      hay:Boolean;
   begin
      recuPrim(listaDetalle.detalle,codBarra);
      hay := true;
      while (hay) loop
         begin
            recuClave(listaDetalle.detalle,codBarra,item);
            mostrarItem(listaProductos,codBarra,item);
            cantidadProductos := cantidadProductos + item;
            recuSig(listaDetalle.detalle,codBarra,codBarra);
         exception
            when tListaDetalle.claveEsUltima => hay := false;
         end;
      end loop;
      Put_Line("--------------------------------");
   exception
      when tListaDetalle.listaVacia =>
         continua("la factura está vacía");
   end;

   procedure cargarItem (listaProductos: in out tListaProductos.tipoLista;detalle: in out tListaDetalle.tipoLista;precioItem: out float) is
      --que hace: Carga un item al detalle de la factura código de barras y cantidad de unidades mostrando su nombre precio por unidad y  precio total y disminuyendo el stock del producto si se confirma el ítem la factura
      --precondiciones:listaProductos = P y P es el listado de productos del local, detalle = D y D es la lista del detalle de productos de una factura
      --poscondiciones: P = P1 y P1 es el listado de productos con el stock reducido del producto seleccionado, D = D1 y D1 es la lista de detalle de la factura con el ítem que se ingresó
      --excepciones:	-errorEnLista,

      codBarra:tClaveProducto;
      producto:tinfoProducto;
      cant: Integer;
      noHayStock:exception;

   begin
      codBarra := To_Unbounded_String(textoNoVacio("ingrese codigo del producto"));
      recuClave(listaProductos,codBarra,producto);
      Put(To_String(producto.nombre & " " & producto.marca & " " & "precio : $")); Put(producto.precio,7,2,0);Put_Line("");
      if (producto.stock = 0) then
         raise noHayStock;
      else
         cant := enteroEnRango("ingrese cantidad de unidades",0,producto.stock);
         precioItem := producto.precio * float(cant);
         Put("El precio total es de : $"); Put(precioItem,7,2,0);Put_Line("");
         if confirma("confirmar item?") then
            insertar(detalle,codBarra,cant);
            producto.stock := producto.stock - cant;
            producto.vendidos := producto.vendidos + cant;
            producto.importeVendido := precioItem;
            modificar(listaProductos,codBarra,producto);
         else
            continua("item cancelado");
         end if;
      end if;
      CLS;
   exception
      when tListaProductos.claveNoExiste => continua("el codigo del producto no existe");
      when tListaDetalle.claveExiste => continua("el producto duplicado en la factura, realize otra factura");
      when noHayStock => continua("no quedan existencias en el local");
      when tListaDetalle.listaLlena => continua("Ocurrio un problema intente mas tarde");
   end ;




   procedure ingresarFecha(fecha: out tFecha; msg: in String) is
      --que hace:
      --precondiciones:
      --poscondiciones:
      --excepciones:*/
   begin
      Put_Line(msg);
      fecha.dia := enteroEnRango("ingrese el dia (DD)",1,31);
      fecha.mes := enteroEnRango("ingrese el mes (MM)",1,12);
      fecha.anio := enteroEnRango("ingrese el año (AAAA)",1000,4000);
   end ingresarFecha;


   procedure cargarInfoVivienda (info: in out tinfoProducto) is
      --que hace: Le pide al usuario que ingrese la información de las viviendas
      --precondiciones: info = I
      --poscondiciones: info =I° y I° es I con la nueva información de la vivienda
      --excepciones:-


   begin
      info.esVivienda := True;
      info.esTechada := confirma("la vivienda es techada?");
      info.dimensiones.alto := numeroReal("Ingrese la altura");
      info.dimensiones.largo := numeroReal("Ingrese el largo");
      info.dimensiones.profundidad := numeroReal("Ingrese la profundidad");
   end ;

   procedure msgListaVacia (msg:in String) is
      --que hace: Le muestra un mensaje al usuario y le pide que presione una tecla
      --precondiciones: msg = M
      --poscondiciones:
      --excepciones:-

   begin
      Put_Line(msg);
      continua("Presione un tecla para continuar");
      CLS;
   end;
   ------------------NIVEL 3----------------------------

   procedure cargarDatosCliente ( k:out tClaveCliente;  i:out tInfoCliente) is
      --que hace: carga la información de un cliente
      --precondiciones:
      --poscondiciones: k = K, K = k con clave i = I, I = registro completo
      --excepciones:-
   begin
      Put_Line("Agrege datos del cliente");
      crear(i.facturas);
      k:= enteroEnRango("Ingrese DNI: ",20000000,90000000);
      Put_Line("Agrege datos del cliente");
      i.nombre:= To_Unbounded_String(textoNoVacio("ingrese Nombre: ")) ;
      i.apellido := To_Unbounded_String(textoNoVacio("ingrese Apellido: ")) ;
      i.Direccion := To_Unbounded_String(textoNoVacio("ingrese Dirección: ")) ;
      ingresarFecha(i.fechaNac,"ingrese Fecha de nacimiento: ");
      CLS;
   end;

   procedure nuevaInfoProducto(info:in out  tInfoProducto)  is
      --que hace: Le pide al usuario que ingrese los datos de un nuevo producto
      --precondiciones: info = I
      --poscondiciones: info = I° y I° es I con la nueva información
      --Excepciones:-

   begin
      info.nombre := To_Unbounded_String(textoNoVacio("ingrese nombre del producto"));
      info.especie:=To_Unbounded_String(textoNoVacio("ingrese para que especie(gato,perro,pez,ave)"));
      info.tamaño:=To_Unbounded_String(textoNoVacio("ingrese para que tamaño(chico,mediano,grande)"));
      info.marca := To_Unbounded_String(textoNoVacio("ingrese la marca del producto"));
      info.modelo := To_Unbounded_String(textoNoVacio("ingrese modelo del producto"));
      info.peso :=numeroReal("ingrese el peso del producto");
      if confirma("Es una vivienda?") then
         cargarInfoVivienda(info);
      end if;
      info.precio := numeroReal("ingrese el precio del producto");
      info.stock := numeroEnt("ingrese cantidad de existencias del producto");
      info.vendidos := 0;
   end ;



   procedure borrarListasClientes (arbolClientes:in out tArbolClientes.tipoArbol;  k:in  tClaveCliente) is
      --Que hace: Elimina la lista de facturas y detalles de un cliente
      --precondiciones: arbolClientes = A, k = K
      --Poscondiciones:--
      --Excepciones:  facturasNoBorradas
      info:tInfoCliente;
      facturaAux:tInfoFactura;
      nFactura:tClaveFactura;
      hay:Boolean;
   begin
      buscar(arbolClientes,k,info);
      hay := True;
      if esVacia(info.facturas) then
         msgListaVacia("No hay facturas que Borrar");
      else
         if confirma("Se eliminaran todas las facturas del cliente, desea continuar? S/N") then
            CLS;
            recuprim(info.facturas,nFactura)	;
            while (hay) loop
               begin
                  recuClave(info.facturas,nFactura,facturaAux);
                  vaciar(facturaAux.detalle);
                  recuSig(info.facturas,nFactura,nFactura);
               exception
                  when tListaFacturas.claveEsUltima =>
                     hay := False;
               end;
            end loop;
            vaciar(info.facturas);
            modificar(arbolClientes,k,info);
         else
            raise facturasNoBorradas;
         end if;
      end if;
   end;

   procedure nuevaInfoCliente( info:in out tInfoCliente) is
      --Que hace: Le pide al usuario que ingrese la información de un nuevo cliente
      --precondiciones:  info = I
      --poscondiciones: info = I° y I° es I con los nuevos datos
      --Excepciones:*/
   begin
      if confirma("¿Quiere modificar el nombre?")then
         info.nombre:= To_Unbounded_String(textoNoVacio("ingrese nuevo nombre: "));
      end if;
      if confirma("¿Quiere modificar el apellido?")then
         info.apellido:=To_Unbounded_String(textoNoVacio("ingrese nuevo apellido: "));
      end if;
      if confirma("¿Quiere modificar la direccion?")then
         info.direccion:=To_Unbounded_String(textoNoVacio("ingrese nueva direccion: "));
      end if;
      if confirma("¿Quiere modificar la fecha de nacimiento?")then
         ingresarFecha(info.fechaNac,"Ingrese fecha de nacimiento: ");
      end if;

   end;

   procedure cargarFactura( productos:in out tListaProductos.tipoLista; clientes:in out tArbolClientes.tipoArbol;dni:in tClaveCliente; info:in tInfoCliente)is
      --que hace: Realiza la carga de una nueva factura a la lista de compras de un cliente en particular
      --precondiciones: listaProductos = P y P es la lista de productos del local, facturas = F y F es la lista de facturas de compras que realizó el cliente.
      --poscondiciones:P = P1 y P1 es la lista de productos con el stock reducido de todos los productos que se compraron, F = F1 y F1 es la lista de facturas con la nueva factura insertada
      --excepciones: recursosInsuficientes

      factura:tInfoFactura;
      precioItem:float;
      subtotal:Float;
      i:Integer;
      infoaux:tInfoCliente := info;

   begin
      crear(factura.detalle);
      subtotal := 0.0;
      loop
         CLS;
         cargarItem(productos,factura.detalle,precioItem);
         subtotal := subtotal + precioItem;
         exit when not confirma("Agregar otro producto?");
      end loop;
      CLS;
      factura.descuento := 0.0;
      factura.subtotal := subtotal;
      if confirma("¿Pago realizado con tarjeta?") then
         factura.descuento := ((subtotal*5.0) / 100.0);
      end if;
      factura.total := factura.subtotal-factura.descuento;
      factura.fecha := fechaHoy;
      i := 1 + longitud(infoaux.facturas);
      insertar(infoaux.facturas,i,factura);
      modificar(clientes,dni,infoaux);
      CLS;
   exception
      when tListaFacturas.listaLlena => continua("Ocurrio un problema intente mas tarde");
   end cargarFactura;

   procedure agregarMasVendidos ( v:in out tMasVendidos; cant:in out integer;  info:in tInfoProducto) is
      --que hace: agrega un producto ordenado de mayor a menor
      --precondiciones: v = V, info = I , cant = C
      --poscondiciones: v = V° y V° con el producto, V° ordenada de mayor a menor, C + 1
      --excepciones:--
      pos:integer;
   begin
      pos := cant;
      while (1 <= pos) and then(v(pos).vendidos < info.vendidos) loop
         v(pos+1) := v(pos);
         pos := pos -1;
      end loop;
      begin
         v(pos+1) := info;
      exception
         when Constraint_Error => null;
      end;
      cant := cant + 1;
      if 10 < cant then
         cant := 10;
      end if;
   end;

   procedure mostrarMasVendidos ( v:in tMasVendidos;cant: in Integer)is
      --que hace: muestra los nombres,cantidad vendidos y importe total de los 10 productos más vendidos
      --precondiciones: v = V y V es el top 10 de ventas del local
      --poscondiciones: --
      --excepciones: --
      i:integer := 0;

   begin
      Put_Line("Los 10 productos mas vendidos");
      while i < cant loop
         i := i + 1;
         Put("Producto: "&(v(i).nombre)&" Vendidos: "&Integer'Image(v(i).vendidos));
         put(" Importe total:");Put(v(i).importeVendido,7,2,0);
         New_Line;
      end loop;
      continua("presione enter para continuar");
      CLS;
   end;


   procedure leerFacturasYmostrar(listaProductos:in tListaProductos.tipoLista; listaFacturas:in tListaFacturas.tipoLista) is
      --que hace: Muestra la factura del cliente
      --precondiciones: listaProductos = LP , listaFacturas = LF
      --poscondiciones:
      --excepciones:*/
      numFactura:tClaveFactura;
      cantidadProductos:Integer;
      factura:tInfoFactura;
      hay:Boolean;
      totalVentas:Float;
      totalDescuento:Float;

   begin
      totalVentas := 0.0;
      totalDescuento := 0.0;
      cantidadProductos := 0;
      recuPrim(listaFacturas,numFactura);
      hay := true;
      while (hay) loop
         begin
            recuClave(listaFacturas,numFactura,factura);
            Put_Line("Compra Numero: " & Integer'Image(numFactura));
            Put_Line("Fecha: "&Integer'Image(factura.fecha.dia)&"/"&Integer'Image(factura.fecha.mes)&"/"&Integer'Image(factura.fecha.anio));
            listarDetalle(listaProductos,factura,cantidadProductos);
            totalVentas := totalVentas + factura.total;
            totalDescuento := totalDescuento + factura.descuento;
            recuSig(listaFacturas,numFactura,numFactura);
         exception
            when tListaFacturas.claveEsUltima => hay := False;
         end;
      end loop;
      mostrarPieListadoFacturas(cantidadProductos,totalVentas,totalDescuento);
      continua("presione una tecla para continuar");
      CLS;
   exception
      when tListaFacturas.listaVacia => continua("El cliente no tiene compras realizadas");
   end;

   procedure sumarTotales(listaFacturas:in tListaFacturas.tipoLista;  totalGastado:out float;  cantidadCompras:out integer)is
      --que hace: Suma los importes y cuenta las facturas de la lista de facturas que ingresa,
      --precondiciones: listaFacturas = L y L es la lista de facturas de un cliente
      --poscondiciones: totalGastado = G y G es la suma de todos los totales de las facturas, cantidadCompras = C y C es la cantidad de facturas que posee la lista
      --excepciones:
      numFactura:tClaveFactura;
      factura:tInfoFactura;
      hay:Boolean;
   begin
      hay := True;
      totalGastado := 0.0;
      recuPrim(listaFacturas,numFactura);
      while (hay) loop
         begin
            recuClave(listaFacturas,numFactura,factura);
            totalGastado := totalGastado + factura.total;
            recuSig(listaFacturas,numFactura,numFactura);
         exception
            when tListaFacturas.claveEsUltima => hay := False;
         end;
      end loop;
      cantidadCompras := longitud(listaFacturas);
   exception
      when tListaFacturas.listaVacia =>
         Put_Line("El Cliente no realizo compras");
   end;

   procedure mostrarCabeceraVentasCliente( nombre:in Unbounded_String; apellido:in Unbounded_String; dni:in integer)is
   begin
      CLS;
      Put_Line("Nombre: "&nombre&" Apellido: "&apellido);
      Put_Line("DNI NRO: "& Integer'Image(dni));
      continua("presione una tecla para continuar");
   end;



   ------------------NIVEL 2----------------------------
   procedure consultaStock(productos:in out tListaProductos.tipoLista)is
      --Que hace : Registra una venta y elimina del stock aquello que se vendió.
      --Precondiciones : arbolClientes = A ; listadoProductos = L

      --Excepciones : -
      prodAux:tInfoProducto;
      codBarra:tClaveProducto;
      hay:Boolean;
   begin
      recuPrim(productos,codBarra);
      hay := true;
      while hay loop
         begin
            recuClave(productos,codBarra,prodAux);
            Put_Line("Nombre: "&prodAux.nombre &" Stock: "& integer'image(prodAux.stock));
            if confirma("¿Quiere realizar pedido al galpon?") then
               CLS;
               prodAux.stock := prodAux.stock + enteroEnRango("Ingrese cantidad de unidades a pedir",1,200);
               modificar(productos,codBarra,prodAux);
            end if;
            CLS;
            recuSig(productos,codBarra,codBarra);
         exception
            when tListaProductos.claveEsUltima => hay := False;
         end;
      end loop;
      CLS;
   exception
      when tListaProductos.listaVacia =>
         msgListaVacia("El listado de productos esta vacio");
   end;


   procedure modificarCliente(arbolClientes:in out tArbolClientes.tipoArbol)is
      --que hace: modifica la información de un cliente
      --pre: clientes=C

      --excepciones: -

      dni:tClaveCliente;
      info:tInfoCliente;
   begin
      if esVacio(arbolClientes) then
         msgListaVacia("No hay clientes para modificar, la lista se encuentra vacia.");
      else
         loop
            begin
               dni := enteroEnRango("Ingrese del DNI del Cliente que quiere modificar",20000000,90000000);
               begin
                  buscar(arbolClientes,dni,info);
                  nuevaInfoCliente(info);
                  modificar(arbolClientes,dni,info);
               exception
                  when tArbolClientes.claveNoExiste =>
                     Put_Line("Cliente no registrado");
                     continua("Presione 'ENTER' para continuar");
                     CLS;
               end;
               exit when not(confirma("¿Desea modificar otro cliente?"));
               CLS;
            end;
         end loop;
         CLS;
      end if;
   end;



   procedure eliminarCliente(arbolClientes:in out tArbolClientes.tipoArbol)is
      --que hace: Elimina un cliente de la lista
      --precondiciones: arbolClientes = A
      --poscondiciones: arbolClientes = A° y A° es A sin el cliente
      --excepciones:
      k:tClaveCliente;
   begin
      if esvacio(arbolClientes) then
         msgListaVacia("No hay clientes para eliminar, la lista se encuentra vacia.");
      else
         k := enteroEnRango("Ingrese DNI del Cliente",20000000,90000000);
         borrarListasClientes(arbolClientes,k);
         suprimir(arbolClientes,k);
         Put_Line("El cliente se elimino satisfactoriamnete");
         continua("Presione un tecla para continuar");
         CLS;
      end if;
   exception
      when tArbolClientes.claveNoExiste =>
         CLS;
         Put_Line("DNI no encontrado");
         continua("Presione un tecla para continuar");
         CLS;
      when facturasNoBorradas =>
         CLS;
         Put_Line("El cliente no fue eliminado");
         continua("Presione un tecla para continuar");
         CLS;
   end;

   procedure agregarCliente (arbolClientes:in out tArbolClientes.tipoArbol) is
      --que hace: Agrega un cliente a la lista según su clave
      --precondiciones: arbolClientes= A

      --excepciones:-

      k:tClaveCliente;
      info:tInfoCliente;
   begin
      cargarDatosCliente(k,info);
      insertar(arbolClientes,k,info);
   exception
      when tArbolClientes.arbolLleno =>
         continua("Ocurrio un error intente mas tarde");
      when tArbolClientes.claveExiste =>
         continua("DNI ya listado");
   end;

   procedure problemaClave (arbolClientes:in out tArbolClientes.tipoArbol;dni:in out tClaveCliente) is
      --Que hace: le pide al usiario que vefifique si tipio bien el dni
      --pre: deni D
      --pos dni = D°
      valido:Boolean;
      infoCLiente:tInfoCliente;
   begin
      valido := false;
      loop
         begin
            if confirma("¿Tipio de manera correcta el DNI?  "& Integer'image(dni)) then
               CLS;
               continua("El Cliente no esta registrado, presione 'ENTER' para agregarlo");
               CLS;
               agregarCliente(arbolClientes);
               dni := enteroEnRango("Ingrese el dni del cliente",20000000,90000000);
            else
               CLS;
               dni := enteroEnRango("Ingrese el dni del cliente",20000000,90000000);
               CLs;
            end if;
            begin
               buscar(arbolClientes,dni,infoCliente);
               valido := true;
            exception
               when tArbolClientes.claveNoExiste =>
                  Put_Line("El DNI es incorrecto");
                  continua("Presione 'ENTER' para continuar");
                  CLS;
            end;
            exit when valido;
         end;
      end loop;
   end;


   procedure mostrarInfoCliente (arbolClientes:in tArbolClientes.tipoArbol) is
      --que hace: Muestra la información de un cliente
      --precondiciones: l = L
      --poscondiciones: --
      --excepciones:-
      k:tClaveCliente;
      info:tInfoCliente;
   begin
      if esVacio(arbolClientes) then
         msgListaVacia("No hay informacion que mostrar, la lista se encuentra vacia.");
      else
         k := enteroEnRango("Ingrese DNI del cliente",20000000,90000000);
         buscar(arbolClientes,k,info);
         Put_Line("Nombre: " & info.nombre);
         Put_Line("Apellido: " & info.apellido);
         Put_Line("Direccion: "& info.direccion);
         Put_Line("Fecha de Nacimiento: "& Integer'Image(info.fechaNac.dia)&"/"& Integer'Image(info.fechaNac.mes)&"/"& Integer'Image(info.fechaNac.anio));
         continua("Presione una tecla para continuar");
         CLS;
      end if;
   exception
      when tArbolClientes.claveNoExiste =>
         Put_Line("DNI no encontrado");
         continua("Presione 'ENTER' para continuar");
         CLS;
   end;

   procedure modificarProductos(productos:in out tListaProductos.tipoLista) is
      --que hace: modifica la información de un producto
      --pre: productos=P

      --excepciones: -

      codBarras:tClaveProducto;
      info:tinfoProducto;
   begin
      if esVacia(productos) then
         msgListaVacia("No hay productos para modificar, la lista esta vacia");
      else

         loop
            begin
               codBarras := To_Unbounded_String(textoNoVacio("Ingrese el codigo de barra del producto que quiere modificar"));
               CLS;
               begin
                  recuClave(productos,codBarras,info);
                  nuevaInfoProducto(info);
                  modificar(productos,codBarras,info);
               exception
                  when tListaProductos.claveNoExiste =>
                     Put_Line("Codigo NO valido");
               end;
               exit when not confirma("Desea modificar otro producto");
            end;
         end loop;
      end if;
      CLS;
   end;

   procedure eliminarProducto (productos:in out tListaProductos.tipoLista) is
      --Que hace : Obtiene los datos de un producto y lo elimina del listado
      --Precondiciones : productos = P
      --Poscondiciones : productos = P° y P° es P sin el producto que se eliminó
      --Excepciones : -
      codBarras:tClaveProducto;
   begin
      if esVacia(productos) then
         msgListaVacia("No hay productos para eliminar, la lista esta vacia");
      else
         codBarras := To_Unbounded_String(textoNoVacio("Ingrese el codigo del producto a eliminar"));
         suprimir(productos,codBarras);
         CLS;
         Put_Line("Se elimino exitosamente el producto de la lista");
         continua("Presione cualquier tecla para continuar");
         CLS;
      end if;
   exception
      when tListaProductos.claveNoExiste =>
         CLS;
         Put_Line("El codigo de barras es erroneo o no esta listado");
         continua("Presione cualquier tecla para continuar");
         CLS;
   end;



   procedure ventasTotales (arbolClientes:in tArbolClientes.tipoArbol) is
      --que hace: muestra un listado de todos los clientes con su número de compras y la cantidad de compras que realizó
      --precondiciones: arbolClientes = A y A es la lista de clientes que posee el local
      --poscondiciones:
      --excepciones:- errorEnLectura
      colaAux:tArbolClientes.ColaRecorridos.tipoCola;
      cliente:tInfoCliente;
      dni:tClaveCliente ;
      precioTotal:float ;
      cantidadVentas:integer;
   begin
      if esVacio(arbolClientes) then
         msgListaVacia("No hay ventas que mostrar, la lista se encuentra vacia.");
      else
         crear(colaAux);
         inOrder(arbolClientes,colaAux);
         while not esVacia(colaAux) loop
            begin
               frente(colaAux,dni) ;
               buscar(arbolClientes,dni,cliente);
               sumarTotales(cliente.facturas,precioTotal,cantidadVentas);
               put_Line(cliente.nombre & " DNI: " & Integer'Image(dni));
               put(" Total Ventas " & Integer'Image(cantidadVentas));
               Put(" Total gastado $ "); Put(precioTotal,7,2,0);
               New_Line;
               New_Line;
               desencolar(colaAux);
            exception
               when tArbolClientes.ColaRecorridos.colaVacia => null;
            end;
         end loop;
         continua("Presione una tecla para continuar: ");
         CLS;
      end if;
   exception
      when tArbolClientes.errorEnCola=>
         Put_Line("Ocurrio un error,intente mas tarde");
   end;



   procedure masVendidos (listaProductos:in tListaProductos.tipoLista) is
      --que hace: Realiza un listado de los productos más vendidos y los muestra por pantalla
      --precondiciones: listaProductos = L
      --poscondiciones: -
      --excepciones:-
      fin:Boolean;
      cant:Integer;
      k:tClaveProducto;
      i:tinfoProducto;
      listaMV:tMasVendidos;
   begin
      recuPrim(listaProductos,k);
      cant := 0;
      fin := TRUE;
      while (fin) loop
         recuClave(listaProductos,k,i);
         agregarMasVendidos(listaMV,cant,i);
         begin
            recuSig(listaProductos,k,k);
         exception
            when tListaProductos.claveEsUltima =>
               fin := False;
         end;
      end loop;
      mostrarMasVendidos(listaMV,cant);
   exception
      when tListaProductos.listaVacia => msgListaVacia("No hay ventas que mostrar, la lista se encuentra vacia.");
   end;


   --que hace: Muestra la factura de ventas de un cliente
   --precondiciones: arbolCliente = A, listaProductos = L
   --poscondiciones:
   --excepciones:-
   procedure ventasCliente (arbolClientes:in tArbolClientes.tipoArbol;listaProductos: in tListaProductos.tipoLista) is
      dni:tClaveCliente;
      cliente:tInfoCliente;
   begin
      if esVacio(arbolClientes) then
         msgListaVacia("No hay ventas que mostrar, la lista se encuentra vacia.");
      else
         dni := numeroEnt("ingrese el dni del cliente que desea listar");
         buscar(arbolClientes,dni,cliente);
         mostrarCabeceraVentasCliente(cliente.nombre,cliente.apellido,dni);
         leerFacturasYmostrar(listaProductos,cliente.facturas);
      end if;
   exception
      when tarbolClientes.claveNoExiste =>
         CLS;
         continua("El cliente no existe");
         CLS;
   end ;




   procedure ingresoAnimal (listaJaulas: in out tListaJaulas.tipoLista;arbolContratos: in out tArbolAlquileresJaulas.tipoArbol) is
      --que hace: permite el alquiler y ocupación de una jaula
      --precondiciones: listaJaulas = L y L es el listado de jaulas del local
      --poscondiciones: L = L1 y L1 es el listado de jaulas con la nueva ocupación
      --excepciones:-

   begin
      continua("no implementado");
      CLS;
   end ingresoAnimal;

   procedure retiroAnimal (listaJaulas: in out tListaJaulas.tipoLista;arbolContratos: in out tArbolAlquileresJaulas.tipoArbol) is
      --qué hace: permite liberar una jaula ocupada de la lista de jaulas
      --precondiciones: lista = L y L es el listado de jaulas del local
      --poscondiciones: L = L1 y L1 es el listado de jaulas con la jaula seleccionada liberada
      --excepciones:-

   begin
      continua("no implementado");
      CLS;
   end retiroAnimal;


   procedure agregarProducto (productos: in out tListaProductos.tipoLista) is
      --Que hace : Obtiene los datos de un producto y lo agrega en los listados
      --Precondiciones : productos = P , productosPref = PP
      --Poscondiciones : productos = P , productosPref = PP , P  y  PP serán modificados
      --Excepciones : -

      codBarra :tClaveProducto;
      infoProducto:tinfoProducto;
   begin
      loop
         codBarra :=To_Unbounded_String(textoNoVacio("Ingrese el codigo de barras del producto"));
         nuevaInfoProducto(infoProducto);
         insertar(productos,codBarra,infoProducto);
         exit when not confirma("¿Desea Ingresar otro producto");
         CLS;
      end loop;
      CLS;
   exception
      when tListaProductos.claveExiste =>
         continua("El prodcuto ya existe, elimine o modifique el producto");
      when tListaProductos.listaLlena => continua("Ocurrio un error intente mas tarde");
   end;


   procedure agregarVenta (arbolClientes:in out tArbolClientes.tipoArbol;listaProductos: in out tListaProductos.tipoLista) is
      --Que hace : Registra una venta y elimina del stock aquello que se vendió.
      --Precondiciones : arbolClientes = A ; listadoProductos = L

      --Excepciones : -


      infoCliente:tInfoCliente;
      dni:tClaveCliente;
   begin
      if esVacio(arbolClientes) then
         continua("El listado de clientes esta vacio, Presione 'ENTER' para agregar un cliente.");
         CLS;
         agregarCliente(arbolClientes);
      end if;
      begin
         dni := enteroEnRango("Ingrese el dni del cliente",20000000,90000000);
         buscar(arbolClientes,dni,infoCliente);
      exception
         when tArbolClientes.claveNoExiste =>
            CLS;
            Put_Line("El DNI es incorrecto");
            continua("Presione 'ENTER' para continuar");
            CLS;
            problemaClave(arbolClientes,dni);
      end;
      cargarFactura(listaProductos,arbolClientes,dni,infoCliente);
   exception
      when tListaProductos.listaLlena => continua("No se pudo cargar la venta intente de nuevo");
      when others => continua("Error No especificado");
         CLS;
   end;


   function mostrarMenuProductos return integer is
      --que hace: muestra el menú de productos
      --precondiciones:-
      --poscondiciones:mostrarMenuProductos = N y N es la opcion que eligio el usuario
      --excepciones:-
      n:Integer;
   begin
      Put_line("Menu de Productos");
      Put_line("Opcion 1: Agregar un nuevo producto");
      Put_Line("Opcion 2: Modificar informacion de un producto");
      Put_Line("Opcion 3: Eliminar un producto");
      Put_Line("Opcion 4: Consultar Stock");
      Put_Line("Presione 0 para volver al menu anterior");
      n := enteroEnRango("Ingrese numero entre",0,4);
      CLS;
      return n;
   end mostrarMenuProductos;


   function mostrarMenuGuarderia return integer is
      --que hace: muestra el menú de alta y baja de las jaulas de guardería
      --precondiciones:
      --poscondiciones: mostrarMenuGuarderia = N y N es la opcion q eligio el usuario
      --excepciones:
      n:Integer;
   begin
      Put_line("Menu Guarderia");
      Put_line("Opcion 1: Alojar nuevo animal en la guarderia");
      Put_Line("Opcion 2: Retirar un animal alojado");
      Put_Line("Opcion 0: Para volver al menu anterior");
      n := enteroEnRango("Ingrese numero entre",0,2);
      CLS;
      return n;
   end mostrarMenuGuarderia;



   function mostrarMenuClientes return integer is
      --que hace: muestra el menú de clientes
      --precondiciones:-
      --poscondiciones:mostrarMenuClientes = N y N es la opcion que eligio el usuario
      --excepciones:-
      n:Integer;
   begin
      Put_line("Menu Clientes");
      Put_line("Opcion 1: Ver informacion de un cliente");
      Put_Line("Opcion 2: Agregar un cliente");
      Put_Line("Opcion 3: Modificar informacion de un cliente");
      Put_Line("Opcion 4: Eliminar un cliente");
      Put_Line("Opcion 0: Para volver al menu anterior");
      n := enteroEnRango("Ingrese numero entre",0,4);
      CLS;
      return n;
   end mostrarMenuClientes;


   function mostrarMenuContabilidad return integer is
      --que hace: muestra el menú de contabilidad
      --precondiciones:-
      --poscondiciones:MostrarMenuContabilidad = N y N es la opcion que eligio el usuario
      --excepciones:-
      n:Integer;
   begin
      Put_line("Menu Contabilidad");
      Put_line("Opcion 1: Agregar nueva venta");
      Put_Line("Opcion 2: Mostrar compras de un cliente");
      Put_Line("Opcion 3: Mostrar 10 productos mas vendidos");
      Put_Line("Opcion 4: Mostrar lista con todas las ventas");
      Put_Line("Opcion 0: Para volver al menu anterior");
      n := enteroEnRango("Ingrese numero entre",0,4);
      CLS;
      return n;
   end mostrarMenuContabilidad;

   ------------------NIVEL 1----------------------------

   procedure menuContabilidad(productos: in out tListaProductos.tipoLista;clientes: in out tArbolClientes.tipoArbol) is
      --qué hace: Permite registrar y visualizar ventas, historial de compras por cliente y que productos son los más vendidos.
      --precondiciones: productos=P y P son todos los productos; clientes=C y C son todos los clientes

      --excepciones:-

      n:Integer;
   begin
      loop
         begin
            n := mostrarMenuContabilidad;
            case (n) is
               when 0 => null;
               when 1 => agregarVenta(clientes,productos);
               when 2 => ventasCliente(clientes,productos);
               when 3 => masVendidos(productos);
               when 4 => ventasTotales(clientes);
               when others => null;
            end case;
            exit when (n = 0);
         end;
      end loop;
   end menuContabilidad;


   procedure menuClientes(clientes: in out tArbolClientes.tipoArbol) is
      --*qué hace:Permite agregar,modificar, visualizar y eliminar clientes
      --precondiciones: clientes= C y C es la lista de clientes

      --excepciones:-

      n:Integer;
   begin
      loop
         begin
            n := mostrarMenuClientes;
            case (n) is
               when 0 => null;
               when 1 => mostrarInfoCliente(clientes);
               when 2 => agregarCliente(clientes);
               when 3 => modificarCliente(clientes);
               when 4 => eliminarCliente(clientes);
               when others => null;
            end case;
            exit when (n = 0);
         end;
      end loop;
   end menuClientes;


   procedure menuGuarderia(listaJaulas: in out tListaJaulas.tipoLista;arbolAlquileresJaulas: in out tArbolAlquileresJaulas.tipoArbol) is
      --que hace: Muestra el menú de guardería para que el usuario elija alguna opción
      --precondiciones: listaJaulas = L
      --poscondiciones: listaJaulas = L° y L° es L con nueva información
      --excepciones:
      n:Integer;
   begin
      loop
         begin
            n := mostrarMenuGuarderia;
            case (n) is
               when 0 => null ;
               when 1 => ingresoAnimal(listaJaulas,arbolAlquileresJaulas);
               when 2 => retiroAnimal(listaJaulas,arbolAlquileresJaulas);
               when others => null;
            end case;
            exit when (n = 0);
         end;
      end loop;
   end menuGuarderia;

   procedure menuProductos(productos: in out tListaProductos.tipoLista) is
      --qué hace:Permite agregar,modificar y eliminar productos
      --precondiciones: productos= P y P es la lista de productos
      --poscondiciones: productos=P° y P° es la lista de productos
      --excepciones:
      n:Integer;
   begin
      loop
         begin
            n := mostrarMenuProductos;
            case (n) is
               when 0 => null ;
               when 1 => agregarProducto(productos);
               when 2 => modificarProductos(productos);
               when 3 => eliminarProducto(productos);
               when 4 => consultaStock(productos);
               when others => null;
            end case;
            exit when (n = 0);
         end;
      end loop;
   end menuProductos;

   procedure crearEstructuras (arbolClientes: out tArbolClientes.tipoArbol;listaProductos: out tListaProductos.tipoLista;listaJaulas: out tListaJaulas.tipoLista;arbolAlquileres: out tArbolAlquileresJaulas.tipoArbol) is
      --que hace: crea estructura de árbol de clientes, y lista de productos y jaulas
      --precondiciones: -
      --Poscondiciones: clientes=C y C son clientes. productos=P y P son productos a comercializar. jaulas=J y J son jaulas a alquilar.
      --excepciones: -
   begin
      crear(arbolClientes);
      crear(listaProductos);
      crear(listaJaulas);
      crear(arbolAlquileres);
   end;

   function mostrarMenu return integer is
      --que hace: muestra el menú principal
      --precondiciones:-
      --poscondiciones:MostrarMenu = N y N es la opcion que eligio el usuario
      --excepciones:-
      n:Integer;
   begin
      Put_line("Sistema De Informacion - Veterinaria");
      Put_line("Opcion 1: Menu de contabilidad");
      Put_Line("Opcion 2: Menu de clientes");
      Put_Line("Opcion 3: Menu de alquiler de jaulas");
      Put_Line("Opcion 4: Menu de productos");
      Put_Line("Opcion 0: Para cerrar el programa");
      n := enteroEnRango("Ingrese numero entre",0,4);
      CLS;
      return n;
   end mostrarMenu;



   ---------------NIVEL 0-----------------

   n: integer;
   arbolClientes: tArbolClientes.tipoArbol;
   listaProductos:tListaProductos.tipoLista;
   listaJaulas:tListaJaulas.tipoLista;
   arbolAlquileres:tArbolAlquileresJaulas.tipoArbol;


begin
   crearEstructuras(arbolClientes,listaProductos,listaJaulas,arbolAlquileres);
   loop
      begin
         n := mostrarMenu;
         case (n) is
            when 0 => null ;
            when 1 => menuContabilidad(listaProductos,arbolClientes);
            when 2 => menuClientes(arbolClientes);
            when 3 => menuGuarderia(listaJaulas,arbolAlquileres);
            when 4 => menuProductos(listaProductos);
            when others => null;
         end case;
         exit when (n = 0);
      end;
   end loop;
   Put_Line("El programa se cerro satisfactoriamente");
end tpfinal;
