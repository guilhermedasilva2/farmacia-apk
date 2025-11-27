import 'package:flutter/material.dart';
import 'package:meu_app_inicial/domain/entities/product.dart';

/// Diálogo de ações para produtos (Prompt 09)
/// Exibe detalhes e oferece 3 opções: Editar, Remover, Fechar
class ProductActionsDialog extends StatelessWidget {
  const ProductActionsDialog({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onRemove,
  });

  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  /// Mostra o diálogo
  static Future<void> show(
    BuildContext context, {
    required Product product,
    required VoidCallback onEdit,
    required VoidCallback onRemove,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false, // ✅ Conforme prompt - não fecha ao tocar fora
      builder: (context) => ProductActionsDialog(
        product: product,
        onEdit: onEdit,
        onRemove: onRemove,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        product.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem do produto (se disponível)
            if (product.imageUrl.isNotEmpty)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    product.imageUrl,
                    height: 120,
                    width: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      width: 120,
                      color: Colors.grey[200],
                      child: const Icon(Icons.medication, size: 48),
                    ),
                  ),
                ),
              ),
            if (product.imageUrl.isNotEmpty) const SizedBox(height: 16),

            // Detalhes do produto
            _buildDetailRow(
              icon: Icons.attach_money,
              label: 'Preço',
              value: 'R\$ ${product.price.toStringAsFixed(2)}',
              valueColor: Colors.teal,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              icon: Icons.inventory_2,
              label: 'Estoque',
              value: '${product.quantity} unidades',
              valueColor: product.quantity > 0 ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              icon: Icons.check_circle,
              label: 'Status',
              value: product.available ? 'Disponível' : 'Indisponível',
              valueColor: product.available ? Colors.green : Colors.red,
            ),
            
            // Descrição
            if (product.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Descrição:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                product.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        // Botão FECHAR
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('FECHAR'),
        ),
        
        // Botão EDITAR
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onEdit();
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.teal,
          ),
          child: const Text('EDITAR'),
        ),
        
        // Botão REMOVER
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onRemove();
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          child: const Text('REMOVER'),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
