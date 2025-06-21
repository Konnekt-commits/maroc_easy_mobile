import 'package:flutter/material.dart';

class DiscreetPriceFilter extends StatefulWidget {
  final double minPrice;
  final double maxPrice;
  final Function(double, double) onPriceChanged;

  const DiscreetPriceFilter({
    Key? key,
    required this.minPrice,
    required this.maxPrice,
    required this.onPriceChanged,
  }) : super(key: key);

  @override
  _DiscreetPriceFilterState createState() => _DiscreetPriceFilterState();
}

class _DiscreetPriceFilterState extends State<DiscreetPriceFilter> {
  late RangeValues _currentRangeValues;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _currentRangeValues = RangeValues(widget.minPrice, widget.maxPrice);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            // En-tête pliable
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.attach_money),
              title: Text(
                'Prix: ${_currentRangeValues.start.round()} - ${_currentRangeValues.end.round()} DH',
                style: TextStyle(fontSize: 14),
              ),
              trailing: Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
              ),
              onTap: () {
                setState(() => _isExpanded = !_isExpanded);
              },
            ),

            // Contenu masquable
            if (_isExpanded) ...[
              Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    RangeSlider(
                      values: _currentRangeValues,
                      min: widget.minPrice,
                      max: widget.maxPrice,
                      divisions: 20,
                      onChanged: (RangeValues values) {
                        setState(() => _currentRangeValues = values);
                        widget.onPriceChanged(values.start, values.end);
                      },
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPriceChip(_currentRangeValues.start, true),
                        _buildPriceChip(_currentRangeValues.end, false),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceChip(double value, bool isMin) {
    return InputChip(
      label: Text('${value.round()} DH'),
      labelStyle: TextStyle(fontSize: 12),
      onPressed: () => _showPriceEditor(isMin),
    );
  }

  void _showPriceEditor(bool isMin) {
    final controller = TextEditingController(
      text:
          (isMin ? _currentRangeValues.start : _currentRangeValues.end)
              .round()
              .toString(),
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isMin ? 'Prix minimum' : 'Prix maximum'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(suffixText: 'DH'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  final newValue =
                      double.tryParse(controller.text) ??
                      (isMin
                          ? _currentRangeValues.start
                          : _currentRangeValues.end);

                  setState(() {
                    if (isMin) {
                      _currentRangeValues = RangeValues(
                        newValue.clamp(
                          widget.minPrice,
                          _currentRangeValues.end,
                        ),
                        _currentRangeValues.end,
                      );
                    } else {
                      _currentRangeValues = RangeValues(
                        _currentRangeValues.start,
                        newValue.clamp(
                          _currentRangeValues.start,
                          widget.maxPrice,
                        ),
                      );
                    }
                  });
                  widget.onPriceChanged(
                    _currentRangeValues.start,
                    _currentRangeValues.end,
                  );
                  Navigator.pop(context);
                },
                child: Text('Valider'),
              ),
            ],
          ),
    );
  }
}
