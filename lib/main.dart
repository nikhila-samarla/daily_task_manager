import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://olwusggdxdvxkgmvwukn.supabase.co',
    publishableKey: 'sb_publishable_IV9OJzKE8BxtfesRoD0wyA_R_DUJx_8',
  );

  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Daily Task Manager',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFFF8F7FC),
      ),
      home: const AuthGate(),
    );
  }
}

      class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session =
            snapshot.data?.session ??
            Supabase.instance.client.auth.currentSession;

        if (session != null) {
          return const MainScreen();
        }

        return const LoginPage();
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLogin = true;
  bool isLoading = false;
  String message = '';

  Future<void> authenticate() async {
    setState(() {
      isLoading = true;
      message = '';
    });

    try {
      final supabase = Supabase.instance.client;

      if (isLogin) {
        await supabase.auth.signInWithPassword(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
      } else {
        await supabase.auth.signUp(
          email: emailController.text.trim(),
          password: passwordController.text,
          data: {
            'full_name': nameController.text.trim(),
          },
        );

        if (!mounted) return;

        setState(() {
          message =
              'Account created! Check your email if verification is required.';
        });
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        message = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        message = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.task_alt,
                size: 65,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 15),
              const Text(
                'Daily Task Manager',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 25),
              Text(
                isLogin ? 'Welcome Back!' : 'Create Your Account',
                style: const TextStyle(fontSize: 21),
              ),
              const SizedBox(height: 20),

              if (!isLogin)
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),

              if (!isLogin) const SizedBox(height: 15),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 15),

              if (message.isNotEmpty)
                Text(
                  message,
                  style: const TextStyle(color: Colors.red),
                ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : authenticate,
                  child: Text(
                    isLoading
                        ? 'Please wait...'
                        : isLogin
                            ? 'Login'
                            : 'Create Account',
                  ),
                ),
              ),

              TextButton(
                onPressed: () {
                  setState(() {
                    isLogin = !isLogin;
                    message = '';
                  });
                },
                child: Text(
                  isLogin
                      ? 'New user? Create an account'
                      : 'Already have an account? Login',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class Task {
  String title;
  String description;
  DateTime date;
  TimeOfDay time;
  String priority;
  bool completed;

  Task({
    required this.title,
    required this.description,
    required this.date,
    required this.time,
     required this.priority,
    this.completed = false,
  });
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;
  String userName = Supabase.instance.client.auth.currentUser
        ?.userMetadata?['full_name'] ?? 'User';

  List<Task> tasks = [];

  int get completed =>
      tasks.where((task) => task.completed).length;

  int get pending => tasks.length - completed;
   List<Task> get todayTasks => tasks.where((task) {
        return task.date.year == DateTime.now().year &&
            task.date.month == DateTime.now().month &&
            task.date.day == DateTime.now().day;
      }).toList();

  void addOrEditTask({Task? existingTask}) {
    final titleController =
        TextEditingController(text: existingTask?.title ?? '');
    final descriptionController =
        TextEditingController(text: existingTask?.description ?? '');

    DateTime selectedDate =
        existingTask?.date ?? DateTime.now();

    TimeOfDay selectedTime =
        existingTask?.time ?? TimeOfDay.now();

    String priority = existingTask?.priority ?? 'Medium';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                existingTask == null ? 'Add New Task' : 'Edit Task',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Task Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Date'),
                      subtitle: Text(
                        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      ),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );

                        if (picked != null) {
                            setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Time'),
                      subtitle: Text(selectedTime.format(context)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );

                        if (picked != null) {
                          setDialogState(() {
                            selectedTime = picked;
                          });
                        }
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: priority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      items: ['High', 'Medium', 'Low']
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            priority = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) {
                      return;
                    }

                    setState(() {
                      if (existingTask == null) {
                        tasks.add(Task(
                          title: titleController.text.trim(),
                          description: descriptionController.text.trim(),
                          date: selectedDate,
                          time: selectedTime,
                          priority: priority,
                        ));
                      } else {
                        existingTask.title = titleController.text.trim();
                        existingTask.description =
                            descriptionController.text.trim();
                        existingTask.date = selectedDate;
                        existingTask.time = selectedTime;
                        existingTask.priority = priority;
                      }
                    });
                     Navigator.pop(dialogContext);
                  },
                  child: const Text('Save Task'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      titleController.dispose();
      descriptionController.dispose();
    });
  }

  void deleteTask(Task task) {
    setState(() {
      tasks.remove(task);
    });
  }

  void toggleTask(Task task, bool? value) {
    setState(() {
      task.completed = value ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        userName: userName,
        tasks: tasks,
        completed: completed,
        pending: pending,
        todayTasks: todayTasks,
        onAdd: () => addOrEditTask(),
        onToggle: toggleTask,
      ),
      MyTasksPage(
        tasks: tasks,
        onAdd: () => addOrEditTask(),
        onEdit: (task) => addOrEditTask(existingTask: task),
        onDelete: deleteTask,
        onToggle: toggleTask,
      ),
      CalendarPage(tasks: tasks),
      ProgressPage(tasks: tasks),
      ProfilePage(userName: userName),
    ];

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'My Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// HOME PAGE

class HomePage extends StatelessWidget {
  final String userName;
  final List<Task> tasks;
  final int completed;
  final int pending;
  final List<Task> todayTasks;
  final VoidCallback onAdd;
  final Function(Task, bool?) onToggle;

  const HomePage({
    super.key,
    required this.userName,
    required this.tasks,
    required this.completed,
    required this.pending,
    required this.todayTasks,
    required this.onAdd,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Welcome, $userName! 👋',
             style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Let’s make today productive.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 25),

          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Total Tasks',
                  value: '${tasks.length}',
                  icon: Icons.task_alt,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  title: 'Completed',
                  value: '$completed',
                  icon: Icons.check_circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Pending',
                  value: '$pending',
                  icon: Icons.pending_actions,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  title: "Today's Tasks",
                  value: '${todayTasks.length}',
                  icon: Icons.today,
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add New Task'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 25),

          const Text(
            "Today's Tasks",
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          if (todayTasks.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  children: [
                    const Icon(
                      Icons.event_note,
                      size: 45,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No tasks for today!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text('Add your first task.'),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: onAdd,
                      child: const Text('Add Task +'),
                    ),
                  ],
                ),
              ),
            )
          else
             ...todayTasks.map((task) => TaskTile(
                  task: task,
                  onToggle: onToggle,
                )),
        ],
      ),
    );
  }
}

// STATISTICS CARD

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.deepPurple, size: 27),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(title, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// TASK TILE

class TaskTile extends StatelessWidget {
  final Task task;
  final Function(Task, bool?) onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Checkbox(
          value: task.completed,
          onChanged: (value) => onToggle(task, value),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: task.completed
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
        subtitle: Text(
          '${task.priority} Priority • ${task.time.format(context)}',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') onEdit?.call();
            if (value == 'delete') onDelete?.call();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}

// MY TASKS PAGE

class MyTasksPage extends StatefulWidget {
  final List<Task> tasks;
  final VoidCallback onAdd;
  final Function(Task) onEdit;
  final Function(Task) onDelete;
  final Function(Task, bool?) onToggle;

  const MyTasksPage({
    super.key,
    required this.tasks,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  State<MyTasksPage> createState() => _MyTasksPageState();
}

class _MyTasksPageState extends State<MyTasksPage> {
  int filter = 0;

  @override
  Widget build(BuildContext context) {
    final filteredTasks = widget.tasks.where((task) {
      if (filter == 1) return !task.completed;
        if (filter == 2) return task.completed;
      return true;
    }).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Tasks',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('All')),
                ButtonSegment(value: 1, label: Text('Pending')),
                ButtonSegment(value: 2, label: Text('Completed')),
              ],
              selected: {filter},
              onSelectionChanged: (value) {
                setState(() {
                  filter = value.first;
                });
              },
            ),
            const SizedBox(height: 18),
            Expanded(
              child: filteredTasks.isEmpty
                  ? const Center(child: Text('No tasks found.'))
                  : ListView(
                      children: filteredTasks.map((task) {
                        return TaskTile(
                          task: task,
                          onToggle: widget.onToggle,
                          onEdit: () => widget.onEdit(task),
                          onDelete: () => widget.onDelete(task),
                        );
                      }).toList(),
                    ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add New Task'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// CALENDAR PAGE//

class CalendarPage extends StatefulWidget {
  final List<Task> tasks;

  const CalendarPage({super.key, required this.tasks});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final dayTasks = widget.tasks.where((task) {
      return task.date.year == selectedDate.year &&
          task.date.month == selectedDate.month &&
          task.date.day == selectedDate.day;
    }).toList();

    final pendingTasks =
        dayTasks.where((task) => !task.completed).toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Calendar',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),

            Card(
              child: CalendarDatePicker(
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                onDateChanged: (date) {
                  setState(() {
                    selectedDate = date;
                  });
                },
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Pending Tasks',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Tasks on ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 10),

            if (pendingTasks.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text('No pending tasks for this date.'),
                  ),
                ),
              )
            else
              ...pendingTasks.map((task) => Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.pending_actions,
                        color: Colors.deepPurple,
                      ),
                      title: Text(task.title),
                      subtitle: Text(
                        '${task.priority} Priority • ${task.time.format(context)}',
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
// PROGRESS PAGE

class ProgressPage extends StatelessWidget {
  final List<Task> tasks;

  const ProgressPage({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final done = tasks.where((task) => task.completed).length;
    final pending = tasks.length - done;
    final progress = tasks.isEmpty ? 0.0 : done / tasks.length;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Progress',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  children: [
                    const Text(
                      'Overall Completion',
                      style: TextStyle(fontSize: 19),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 13,
                        backgroundColor: Colors.deepPurple.shade100,
                      ),
                    ),

                    const SizedBox(height: 15),

                    Text(
                      '${(progress * 100).round()}% Completed',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            StatCard(
              title: 'Total Tasks',
              value: '${tasks.length}',
              icon: Icons.task_alt,
            ),

            StatCard(
              title: 'Completed Tasks',
              value: '$done',
              icon: Icons.check_circle,
            ),

            StatCard(
              title: 'Pending Tasks',
              value: '$pending',
              icon: Icons.pending_actions,
            ),

            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Task Progress Chart',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    ProgressBarRow(
                      label: 'Completed',
                      value: done,
                      total: tasks.length,
                      color: Colors.green,
                    ),

                    const SizedBox(height: 20),

                    ProgressBarRow(
                      label: 'Pending',
                      value: pending,
                      total: tasks.length,
                      color: Colors.deepPurple,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProgressBarRow extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;

  const ProgressBarRow({
    super.key,
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('$value / $total'),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: total == 0 ? 0 : value / total,
          minHeight: 12,
          backgroundColor: Colors.grey.shade200,
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
      ],
    );
  }
}
// PROFILE PAGE

class ProfilePage extends StatelessWidget {
  final String userName;

  const ProfilePage({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Profile',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.deepPurple,
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 55,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text('Daily Task Manager User'),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Edit Profile'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.notifications_active_outlined),
                    title: Text('Notifications'),
                    trailing: Text(
                      'ON',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Change Password'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Settings'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}