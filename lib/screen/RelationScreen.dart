
import 'package:flutter/material.dart';
import '../services/ElementService.dart';
import 'dart:async';

class RelationScreen extends StatefulWidget {
	final String relationCode;
	const RelationScreen({super.key, required this.relationCode});

	@override
	State<RelationScreen> createState() => _RelationScreenState();
}

class _RelationScreenState extends State<RelationScreen> {
	final TextEditingController _controller = TextEditingController();
	List<Map<String, dynamic>> messages = [];
	bool isLoading = false;
	String? errorMessage;
	Timer? _pollTimer;

@override
	void initState() {
		super.initState();
		fetchMessages();
		_pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
		  if (mounted) fetchMessages();
		});
	}

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

	Future<void> fetchMessages() async {
		setState(() {
			isLoading = true;
			errorMessage = null;
		});
		try {
			final result = await ElementService.fetchElements(widget.relationCode);
			setState(() {
				messages = result;
				isLoading = false;
			});
		} catch (e) {
			setState(() {
				isLoading = false;
				errorMessage = 'Erreur lors de la récupération des messages :\n' + e.toString();
			});
		}
	}

	Future<void> sendMessage() async {
		final text = _controller.text.trim();
		if (text.isEmpty) return;
		setState(() {
			isLoading = true;
			errorMessage = null;
		});
		try {
			final ok = await ElementService.sendElement(
				relationCode: widget.relationCode,
				type: 'MESSAGE',
				value: text,
			);
			if (ok) {
				_controller.clear();
				await fetchMessages();
			} else {
				setState(() {
					errorMessage = 'Erreur lors de l\'envoi du message.';
				});
			}
		} catch (e) {
			setState(() {
				errorMessage = 'Erreur lors de l\'envoi du message :\n' + e.toString();
			});
		} finally {
			setState(() {
				isLoading = false;
			});
		}
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						const Text('Conversation'),
						Text(
							'RelationCode: ${widget.relationCode}',
							style: const TextStyle(fontSize: 12, color: Colors.white70),
						),
					],
				),
			),
			body: Column(
				children: [
					if (errorMessage != null)
						Container(
							color: Colors.red[100],
							padding: const EdgeInsets.all(8),
							margin: const EdgeInsets.all(8),
							child: Row(
								children: [
									const Icon(Icons.error, color: Colors.red),
									const SizedBox(width: 8),
									Expanded(child: Text(errorMessage!, style: const TextStyle(color: Colors.red))),
									IconButton(
										icon: const Icon(Icons.close),
										onPressed: () => setState(() => errorMessage = null),
									),
								],
							),
						),
					Expanded(
						child: RefreshIndicator(
						  onRefresh: fetchMessages,
						  child: isLoading
								? const Center(child: CircularProgressIndicator())
								: messages.isEmpty
									? const Center(child: Text('Aucun message.'))
									: ListView.builder(
										reverse: true,
										itemCount: messages.length,
										itemBuilder: (context, i) {
											final msg = messages[messages.length - 1 - i];
											return ListTile(
												title: Text(msg['value'] ?? ''),
												subtitle: Text(msg['type'] ?? ''),
											);
										},
									),
						),
					),
					Padding(
						padding: const EdgeInsets.all(8.0),
						child: Row(
							children: [
								Expanded(
									child: TextField(
										controller: _controller,
										decoration: const InputDecoration(
											hintText: 'Votre message...',
										),
									),
								),
								IconButton(
									icon: const Icon(Icons.send),
									onPressed: isLoading ? null : sendMessage,
								),
							],
						),
					),
				],
			),
		);
	}
}
