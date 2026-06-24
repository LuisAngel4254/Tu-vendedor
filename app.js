// Configuración de Supabase
const SUPABASE_URL = 'https://pvmhgqmarshjkmbnclqj.supabase.co';  // ← REEMPLAZA
const SUPABASE_KEY = 'sb_publishable_KPwoyQ1eVh7PoMUJt0VHIA_cdc7sKrZ';  // ← REEMPLAZA
const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_KEY);

let carrito = [];
let productosActivos = [];

// Cargar productos al iniciar
document.addEventListener('DOMContentLoaded', cargarProductos);

async function cargarProductos() {
    const { data, error } = await supabase
        .from('productos')
        .select('*')
        .eq('activo', true)
        .order('orden', { ascending: true });

    if (error) {
        console.error('Error:', error);
        document.getElementById('loading').textContent = 'Error cargando productos';
        return;
    }

    productosActivos = data;
    mostrarCatalogo(data);
}

function mostrarCatalogo(productos) {
    const catalogo = document.getElementById('catalogo');
    document.getElementById('loading').style.display = 'none';

    if (productos.length === 0) {
        catalogo.innerHTML = '<p style="text-align:center;padding:40px;">No hay productos disponibles</p>';
        return;
    }

    catalogo.innerHTML = productos.map(prod => `
        <div class="producto ${prod.stock === 0 ? 'inactivo' : ''}" data-id="${prod.modulo_id}">
            <img src="${prod.imagen_url || 'assets/placeholder.png'}" alt="${prod.nombre}">
            <h3>${prod.nombre}</h3>
            <p>${prod.composicion}</p>
            
            ${prod.tamanos && prod.tamanos.length > 0 ? `
                <select class="select-tamano" id="tamano-${prod.modulo_id}">
                    ${prod.tamanos.map((tam, i) => `
                        <option value="${i}">${tam} - S/ ${prod.precios[i]}</option>
                    `).join('')}
                </select>
                <div class="precio">                    S/ ${prod.precios[0]}
                </div>
            ` : `
                <div class="precio">S/ ${prod.precios?.[0] || '0.00'}</div>
            `}
            
            <div class="stock">
                Stock: ${prod.stock} unidades
            </div>
            
            <button class="btn-agregar" 
                    onclick="agregarAlCarrito('${prod.modulo_id}')"
                    ${prod.stock === 0 ? 'disabled' : ''}>
                ${prod.stock === 0 ? 'Sin Stock' : 'Agregar al Carrito'}
            </button>
        </div>
    `).join('');
}

function agregarAlCarrito(moduloId) {
    const producto = productosActivos.find(p => p.modulo_id === moduloId);
    if (!producto || producto.stock === 0) return;

    const selectTamano = document.getElementById(`tamano-${moduloId}`);
    const indiceTamano = selectTamano ? parseInt(selectTamano.value) : 0;

    const itemExistente = carrito.find(item => 
        item.modulo_id === moduloId && item.indiceTamano === indiceTamano
    );

    if (itemExistente) {
        if (itemExistente.cantidad < producto.stock) {
            itemExistente.cantidad++;
        } else {
            alert('No hay más stock disponible');
            return;
        }
    } else {
        carrito.push({
            modulo_id: moduloId,
            nombre: producto.nombre,
            tamano: producto.tamanos?.[indiceTamano] || 'Único',
            precio: producto.precios?.[indiceTamano] || 0,
            cantidad: 1,
            indiceTamano: indiceTamano
        });
    }

    actualizarCarritoUI();
}
function actualizarCarritoUI() {
    const count = carrito.reduce((sum, item) => sum + item.cantidad, 0);
    document.getElementById('carrito-count').textContent = count;
    
    const flotante = document.getElementById('carrito-flotante');
    flotante.style.display = count > 0 ? 'flex' : 'none';
}

function verCarrito() {
    const modal = document.getElementById('modal-carrito');
    const itemsDiv = document.getElementById('items-carrito');
    
    itemsDiv.innerHTML = carrito.map(item => `
        <div>
            <div>
                <strong>${item.nombre}</strong><br>
                <small>${item.tamano} x ${item.cantidad}</small>
            </div>
            <div>S/ ${(item.precio * item.cantidad).toFixed(2)}</div>
        </div>
    `).join('');

    const total = carrito.reduce((sum, item) => sum + (item.precio * item.cantidad), 0);
    document.getElementById('total-pago').textContent = total.toFixed(2);
    
    modal.style.display = 'flex';
}

function cerrarCarrito() {
    document.getElementById('modal-carrito').style.display = 'none';
}

async function finalizarPedido() {
    if (carrito.length === 0) {
        alert('El carrito está vacío');
        return;
    }

    const metodoPago = document.getElementById('metodo-pago').value;
    const total = carrito.reduce((sum, item) => sum + (item.precio * item.cantidad), 0);

    const pedido = {
        cliente: {
            telefono: new URLSearchParams(window.location.search).get('tel') || 'desconocido'
        },
        pedido: carrito.map(item => ({
            modulo_id: item.modulo_id,
            nombre: item.nombre,
            tamano: item.tamano,            cantidad: item.cantidad,
            precio_unitario: item.precio
        })),
        total: total,
        metodo_pago: metodoPago,
        timestamp: new Date().toISOString()
    };

    // Enviar a Supabase
    const { error } = await supabase
        .from('pedidos')
        .insert([pedido]);

    if (error) {
        alert('Error al procesar el pedido: ' + error.message);
        return;
    }

    // Redirigir a WhatsApp con el resumen
    const mensaje = `🛍️ *Nuevo Pedido*\n\n` +
        carrito.map(item => `• ${item.nombre} (${item.tamano}) x${item.cantidad}\n  S/ ${(item.precio * item.cantidad).toFixed(2)}`).join('\n') +
        `\n*Total: S/ ${total.toFixed(2)}*\nMétodo: ${metodoPago.toUpperCase()}`;

    const whatsappUrl = `https://wa.me/?text=${encodeURIComponent(mensaje)}`;
    window.location.href = whatsappUrl;
}
