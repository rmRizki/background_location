import 'package:background_location/common/constant.dart';
import 'package:background_location/data/database_helper.dart';
import 'package:background_location/data/models/check_list.dart';
import 'package:background_location/data/models/ticket.dart';
import 'package:flutter/material.dart';

class AddTicketPage extends StatefulWidget {
  const AddTicketPage({Key? key}) : super(key: key);

  @override
  _AddTicketPageState createState() => _AddTicketPageState();
}

class _AddTicketPageState extends State<AddTicketPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _departChecklistController = <TextEditingController>[];
  final _arriveChecklistController = <TextEditingController>[];
  final _databaseHelper = DatabaseHelper();

  final _emptyFieldWarning = 'This field cannot be empty';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (var element in _departChecklistController) {
      element.dispose();
    }
    for (var element in _arriveChecklistController) {
      element.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Ticket')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: _buildForm(),
            ),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      children: [
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
          controller: _titleController,
          validator: (value) {
            return (value == null || value.isEmpty) ? _emptyFieldWarning : null;
          },
        ),
        const SizedBox(height: 8),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          minLines: 1,
          controller: _descriptionController,
          validator: (value) {
            return (value == null || value.isEmpty) ? _emptyFieldWarning : null;
          },
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _departChecklistController.length >= 5
              ? null
              : () {
                  if (_departChecklistController.length >= 5) return;
                  setState(
                    () =>
                        _departChecklistController.add(TextEditingController()),
                  );
                },
          child: const Text('Add Departure Checklist +'),
        ),
        const SizedBox(height: 8),
        for (var controller in _departChecklistController)
          _buildChecklistField(
            controller,
            onClear: () => setState(
              () => _departChecklistController.remove(controller),
            ),
          ),
        TextButton(
          onPressed: _arriveChecklistController.length >= 5
              ? null
              : () {
                  if (_arriveChecklistController.length >= 5) return;
                  setState(
                    () =>
                        _arriveChecklistController.add(TextEditingController()),
                  );
                },
          child: const Text('Add Arrival Checklist +'),
        ),
        const SizedBox(height: 8),
        for (var controller in _arriveChecklistController)
          _buildChecklistField(
            controller,
            onClear: () => setState(
              () => _arriveChecklistController.remove(controller),
            ),
          ),
      ],
    );
  }

  Widget _buildChecklistField(
    TextEditingController controller, {
    required VoidCallback onClear,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextFormField(
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.clear),
          ),
        ),
        controller: controller,
        validator: (value) {
          return (value == null || value.isEmpty) ? _emptyFieldWarning : null;
        },
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          if (_formKey.currentState!.validate()) {
            try {
              final ticketId = await _databaseHelper.insertData(
                TableName.ticket,
                Ticket(
                  title: _titleController.text,
                  description: _descriptionController.text,
                ).toJson(),
              );
              for (var element in _departChecklistController) {
                await _databaseHelper.insertData(
                  TableName.checklist,
                  CheckListItem(
                    title: element.text,
                    type: ChecklistType.depart.name,
                    ticketId: ticketId,
                  ).toJson(),
                );
              }
              for (var element in _arriveChecklistController) {
                await _databaseHelper.insertData(
                  TableName.checklist,
                  CheckListItem(
                    title: element.text,
                    type: ChecklistType.arrive.name,
                    ticketId: ticketId,
                  ).toJson(),
                );
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ticket Created')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$e')),
              );
            }
          }
        },
        child: const Text('Create Ticket'),
      ),
    );
  }
}
