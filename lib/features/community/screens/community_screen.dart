import 'package:flutter/material.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Community",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: Colors.white),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none, color: Colors.white),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          CommunityPost(
            name: "Tommy Gaming",
            time: "2 min ago",
            message:
                "Welcome to GenLink KH Community! 🎉 Share your ideas, ask questions, and connect with everyone.",
          ),
          SizedBox(height: 16),
          CommunityPost(
            name: "John Doe",
            time: "15 min ago",
            message:
                "Flutter 3.35 is amazing! The performance is much smoother than before.",
          ),
          SizedBox(height: 16),
          CommunityPost(
            name: "Jane Smith",
            time: "1 hour ago",
            message:
                "Anyone interested in joining our developer meetup this weekend?",
          ),
          SizedBox(height: 16),
          CommunityPost(
            name: "Alex",
            time: "3 hours ago",
            message: "Just finished building my first Flutter application! 🚀",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2563EB),
        onPressed: () {},
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class CommunityPost extends StatelessWidget {
  final String name;
  final String time;
  final String message;

  const CommunityPost({
    super.key,
    required this.name,
    required this.time,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFF2563EB),
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_horiz, color: Colors.white54),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ActionButton(icon: Icons.favorite_border, text: "Like"),
              _ActionButton(icon: Icons.chat_bubble_outline, text: "Comment"),
              _ActionButton(icon: Icons.share_outlined, text: "Share"),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ActionButton({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}
