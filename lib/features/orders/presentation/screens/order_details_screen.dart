import 'package:flutter/material.dart';
import 'package:meu_app_inicial/features/orders/domain/entities/order.dart';

class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final order = ModalRoute.of(context)!.settings.arguments as Order;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes do Pedido #${order.id.substring(0, 8)}'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTrackingStepper(context, order.status),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Endereço de Entrega
                  if (order.deliveryAddress != null) ...[
                    Row(
                      children: [
                        Icon(Icons.location_on, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Endereço de Entrega',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.fullAddress,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  Text(
                    'Itens do Pedido',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...order.items.map((item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.medication),
                    ),
                    title: Text(item.name.isEmpty ? 'Produto' : item.name), // Fallback if name missing
                    subtitle: Text('${item.quantity} unidade(s)'),
                    trailing: Text(
                      'R\$ ${(item.unitPrice * item.quantity).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Geral',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'R\$ ${order.total.toStringAsFixed(2)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold, 
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingStepper(BuildContext context, OrderStatus currentStatus) {
    int currentStep = 0;
    switch (currentStatus) {
      case OrderStatus.pending:
        currentStep = 0;
        break;
      case OrderStatus.paid:
        currentStep = 1;
        break;
      case OrderStatus.shipped:
        currentStep = 2;
        break;
      case OrderStatus.delivered:
        currentStep = 3;
        break;
      case OrderStatus.cancelled:
        currentStep = -1; // Special case
        break;
    }

    if (currentStep == -1) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        color: Colors.red.withValues(alpha: 0.1),
        child: Column(
          children: [
            const Icon(Icons.cancel, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(
              'Pedido Cancelado',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.red),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.local_shipping_outlined),
                const SizedBox(width: 8),
                Text(
                  'Acompanhamento',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Stepper(
            physics: const NeverScrollableScrollPhysics(),
            currentStep: currentStep,
            controlsBuilder: (_, __) => const SizedBox(), // Hide buttons
            steps: [
              Step(
                title: const Text('Pedido Confirmado'),
                subtitle: const Text('Aguardando pagamento'),
                content: const SizedBox(),
                isActive: currentStep >= 0,
                state: currentStep > 0 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: const Text('Pagamento Aprovado'),
                subtitle: const Text('Preparando envio'),
                content: const SizedBox(),
                isActive: currentStep >= 1,
                state: currentStep > 1 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: const Text('Em Transporte'),
                subtitle: const Text('O pedido está a caminho'),
                content: const SizedBox(), // Here we could add "Mock Map" or "Geolocation" text
                isActive: currentStep >= 2,
                state: currentStep > 2 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: const Text('Entregue'),
                subtitle: const Text('Pedido recebido pelo cliente'),
                content: const SizedBox(),
                isActive: currentStep >= 3,
                state: currentStep > 3 ? StepState.complete : StepState.indexed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
