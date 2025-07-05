import 'package:flutter/material.dart';

class MyManagerScreen extends StatelessWidget {
  const MyManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Optimization Guide'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildPracticeItem(
                title: "1. Prioritize Tasks (Eisenhower Matrix)",
                details: "Divide tasks into four categories:\n\n"
                    "• Urgent & Important (Do now)\n"
                    "• Important, Not Urgent (Schedule)\n"
                    "• Urgent, Not Important (Delegate)\n"
                    "• Neither (Eliminate)\n\n"
                    "This helps focus on what truly matters.",
              ),
              _buildPracticeItem(
                title: "2. Time Blocking",
                details: "Assign specific time blocks for different activities:\n\n"
                    "• 25-50 minute focused work sessions\n"
                    "• 5-10 minute breaks between blocks\n"
                    "• Color-code categories (work, personal, learning)\n\n"
                    "Protect these blocks like important meetings.",
              ),
              _buildPracticeItem(
                title: "3. The 2-Minute Rule",
                details: "If a task takes less than 2 minutes:\n\n"
                    "• Do it immediately\n"
                    "• Prevents small tasks from piling up\n"
                    "• Reduces mental clutter\n\n"
                    "From David Allen's Getting Things Done methodology.",
              ),
              _buildPracticeItem(
                title: "4. Batch Similar Tasks",
                details: "Group similar activities together:\n\n"
                    "• Respond to all emails at set times\n"
                    "• Make all phone calls in one batch\n"
                    "• Do all errands in one trip\n\n"
                    "Reduces context-switching time by up to 40%.",
              ),
              _buildPracticeItem(
                title: "5. Set SMART Goals",
                details: "Goals should be:\n\n"
                    "• Specific\n"
                    "• Measurable\n"
                    "• Achievable\n"
                    "• Relevant\n"
                    "• Time-bound\n\n"
                    "Example: 'Increase sales by 15% in Q3' vs 'Get more sales'.",
              ),
              _buildPracticeItem(
                title: "6. Eliminate Decision Fatigue",
                details: "Reduce trivial decisions:\n\n"
                    "• Plan outfits the night before\n"
                    "• Meal prep for the week\n"
                    "• Create morning/evening routines\n\n"
                    "Preserves mental energy for important decisions.",
              ),
              _buildPracticeItem(
                title: "7. Use the Pomodoro Technique",
                details: "Work in 25-minute intervals:\n\n"
                    "• 25 minutes focused work\n"
                    "• 5 minute break\n"
                    "• After 4 cycles, take 15-30 minute break\n\n"
                    "Boosts focus while preventing burnout.",
              ),
              _buildPracticeItem(
                title: "8. Implement the 80/20 Rule",
                details: "The Pareto Principle states:\n\n"
                    "• 80% of results come from 20% of efforts\n"
                    "• Identify your high-impact activities\n"
                    "• Focus on tasks that drive most value\n\n"
                    "Eliminate or delegate low-yield activities.",
              ),
              _buildPracticeItem(
                title: "9. Single-Tasking",
                details: "Contrary to popular belief:\n\n"
                    "• Multitasking reduces productivity by 40%\n"
                    "• Focus completely on one task at a time\n"
                    "• Turn off notifications during deep work\n\n"
                    "Quality beats quantity in task completion.",
              ),
              _buildPracticeItem(
                title: "10. Weekly Review System",
                details: "Every week:\n\n"
                    "• Review accomplishments\n"
                    "• Plan the coming week\n"
                    "• Clear inboxes and workspaces\n"
                    "• Reflect on what worked/didn't\n\n"
                    "Takes 30-60 minutes but saves hours.",
              ),
              _buildPracticeItem(
                title: "11. Energy Management",
                details: "Schedule tasks by energy levels:\n\n"
                    "• Do creative work when most alert\n"
                    "• Save routine tasks for low-energy times\n"
                    "• Take walking breaks to recharge\n\n"
                    "Align work with natural productivity rhythms.",
              ),
              _buildPracticeItem(
                title: "12. The 5-Second Rule",
                details: "When you hesitate to start a task:\n\n"
                    "• Count down 5-4-3-2-1\n"
                    "• Take action immediately\n"
                    "• Prevents procrastination\n\n"
                    "From Mel Robbins' motivation technique.",
              ),
              _buildPracticeItem(
                title: "13. Digital Minimalism",
                details: "Reduce digital distractions:\n\n"
                    "• Turn off non-essential notifications\n"
                    "• Use website blockers during work\n"
                    "• Schedule social media time\n\n"
                    "Recover 1-3 hours daily for most people.",
              ),
              _buildPracticeItem(
                title: "14. Meeting Optimization",
                details: "Make meetings productive:\n\n"
                    "• Set clear agendas in advance\n"
                    "• Keep under 30 minutes when possible\n"
                    "• Only include essential people\n"
                    "• End with clear action items\n\n"
                    "Consider if an email could replace the meeting.",
              ),
              _buildPracticeItem(
                title: "15. Reflection Practice",
                details: "Daily 5-minute reflection:\n\n"
                    "• What went well today?\n"
                    "• What could be improved?\n"
                    "• What will I do differently tomorrow?\n\n"
                    "Creates continuous improvement cycles.",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPracticeItem({required String title, required String details}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0).copyWith(top: 0),
            child: Text(
              details,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}