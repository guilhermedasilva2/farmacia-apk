import 'package:flutter/material.dart';

class CheckoutDialog extends StatefulWidget {
  const CheckoutDialog({super.key});

  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<CheckoutDialog> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _numberController = TextEditingController();
  final _complementController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _cepController = TextEditingController();
  
  String _paymentMethod = 'pix';

  @override
  void dispose() {
    _addressController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _cepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Finalizar Compra'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Endereço de Entrega',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                
                // CEP
                TextFormField(
                  controller: _cepController,
                  decoration: const InputDecoration(
                    labelText: 'CEP',
                    hintText: '00000-000',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty ? 'Informe o CEP' : null,
                ),
                const SizedBox(height: 12),
                
                // Endereço
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Endereço',
                    hintText: 'Rua, Avenida, etc.',
                    prefixIcon: Icon(Icons.home),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Informe o endereço' : null,
                ),
                const SizedBox(height: 12),
                
                // Número e Complemento
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _numberController,
                        decoration: const InputDecoration(
                          labelText: 'Número',
                          prefixIcon: Icon(Icons.pin),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => value == null || value.isEmpty ? 'Obrigatório' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _complementController,
                        decoration: const InputDecoration(
                          labelText: 'Complemento',
                          hintText: 'Apto, Bloco, etc.',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Bairro
                TextFormField(
                  controller: _neighborhoodController,
                  decoration: const InputDecoration(
                    labelText: 'Bairro',
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Informe o bairro' : null,
                ),
                const SizedBox(height: 12),
                
                // Cidade e Estado
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          labelText: 'Cidade',
                          prefixIcon: Icon(Icons.location_city),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Informe a cidade' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _stateController,
                        decoration: const InputDecoration(
                          labelText: 'UF',
                          hintText: 'SP',
                        ),
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 2,
                        validator: (value) => value == null || value.isEmpty ? 'Informe UF' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                const Divider(),
                const SizedBox(height: 12),
                
                const Text(
                  'Forma de Pagamento',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                
                RadioGroup<String>(
                  groupValue: _paymentMethod,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _paymentMethod = value);
                    }
                  },
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('PIX'),
                        leading: Radio<String>(value: 'pix'),
                        onTap: () => setState(() => _paymentMethod = 'pix'),
                      ),
                      ListTile(
                        title: const Text('Cartão de Crédito'),
                        leading: Radio<String>(value: 'credit_card'),
                        onTap: () => setState(() => _paymentMethod = 'credit_card'),
                      ),
                      ListTile(
                        title: const Text('Boleto'),
                        leading: Radio<String>(value: 'boleto'),
                        onTap: () => setState(() => _paymentMethod = 'boleto'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'payment_method': _paymentMethod,
                'delivery_address': _addressController.text,
                'delivery_number': _numberController.text,
                'delivery_complement': _complementController.text,
                'delivery_neighborhood': _neighborhoodController.text,
                'delivery_city': _cityController.text,
                'delivery_state': _stateController.text.toUpperCase(),
                'delivery_cep': _cepController.text,
              });
            }
          },
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
