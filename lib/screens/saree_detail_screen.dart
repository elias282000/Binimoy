import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/rental_calendar.dart';

enum TransactionType { buy, rent, swap }
enum TransactionStatus { pending, approved, rejected }

class SareeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> saree;

  const SareeDetailScreen({
    super.key,
    required this.saree,
  });

  @override
  State<SareeDetailScreen> createState() => _SareeDetailScreenState();
}

class _SareeDetailScreenState extends State<SareeDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Saree Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                widget.saree['imageUrl'] ?? '',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.error),
                  );
                },
              ),
            ),
            
            // Details section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.saree['name'] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '৳${widget.saree['price'] ?? 0}',
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.saree['description'] ?? 'No description available',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleBuy,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Buy Now',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _handleRent,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.green),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Rent',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Implement swap functionality
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Swap',
                            style: TextStyle(fontSize: 16),
                          ),
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

  Future<void> _handleBuy() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to make a purchase')),
      );
      return;
    }

    try {
      // Ensure saree ID exists
      final String sareeId = widget.saree['id'] ?? 
          (widget.saree['documentId'] as String?) ?? 
          '';
      
      if (sareeId.isEmpty) {
        throw Exception('Invalid saree ID');
      }

      // Create transaction document
      final transactionRef = await FirebaseFirestore.instance.collection('transactions').add({
        'sareeId': sareeId,
        'sareeName': widget.saree['name'] ?? 'Unknown',
        'sareeImage': widget.saree['imageUrl'] ?? '',
        'buyerId': user.uid,
        'buyerName': user.displayName ?? 'Anonymous',
        'sellerId': widget.saree['userId'] ?? '',
        'sellerName': widget.saree['userName'] ?? 'Unknown',
        'type': TransactionType.buy.toString(),
        'status': TransactionStatus.pending.toString(),
        'amount': widget.saree['price'] ?? 0.0,
        'startDate': DateTime.now(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update the saree document
      await FirebaseFirestore.instance
          .collection('sarees')
          .doc(sareeId)
          .update({
        'isAvailable': false,
        'lastTransactionId': transactionRef.id,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase request sent successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      print('Transaction error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to process purchase. Please try again.')),
      );
    }
  }

  Future<void> _handleRent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to rent')),
      );
      return;
    }

    if (user.uid == widget.saree['userId']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot rent your own saree')),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Rental Dates',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 400,
              child: RentalCalendar(
                sareeId: widget.saree['id'],
                onDateSelected: (start, end) async {
                  Navigator.pop(context);
                  
                  try {
                    final days = end.difference(start).inDays + 1;
                    final amount = (widget.saree['price'] as num) * 0.1 * days;

                    // Create rental transaction
                    final transactionRef = await FirebaseFirestore.instance
                        .collection('transactions')
                        .add({
                      'sareeId': widget.saree['id'],
                      'sareeName': widget.saree['name'],
                      'sareeImage': widget.saree['imageUrl'],
                      'buyerId': user.uid,
                      'buyerName': user.displayName ?? 'Anonymous',
                      'sellerId': widget.saree['userId'],
                      'sellerName': widget.saree['userName'],
                      'type': TransactionType.rent.toString(),
                      'status': TransactionStatus.pending.toString(),
                      'amount': amount,
                      'startDate': start,
                      'endDate': end,
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    // Update saree status
                    await FirebaseFirestore.instance
                        .collection('sarees')
                        .doc(widget.saree['id'])
                        .update({
                      'rentalStatus': 'pending',
                      'lastTransactionId': transactionRef.id,
                    });

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Rental request sent successfully!')),
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    print('Rental error: $e');
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to process rental. Please try again.')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}