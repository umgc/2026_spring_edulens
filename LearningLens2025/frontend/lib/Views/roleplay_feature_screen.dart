import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/database/ai_logging_singleton.dart';
import 'package:learninglens_app/Api/llm/DeepSeek_api.dart';
import 'package:learninglens_app/Api/llm/enum/llm_enum.dart';
import 'package:learninglens_app/Api/llm/grok_api.dart';
import 'package:learninglens_app/Api/llm/llm_api_modules_base.dart';
import 'package:learninglens_app/Api/llm/local_llm_service.dart';
import 'package:learninglens_app/Api/llm/openai_api.dart';
import 'package:learninglens_app/Api/llm/perplexity_api.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Api/lms/lms_interface.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/Views/ai_log_screen.dart';
import 'package:learninglens_app/beans/ai_log.dart';
import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/chatLog.dart';
import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/beans/participant.dart';
import 'package:learninglens_app/beans/roleplay_scenario.dart';
import 'package:learninglens_app/services/LLMContextBuilder.dart';
import 'package:learninglens_app/services/local_storage_service.dart';
import 'package:learninglens_app/services/roleplay_scenario_service.dart';

class RoleplayFeatureScreen extends StatefulWidget {
  const RoleplayFeatureScreen({super.key});

  @override
  State<RoleplayFeatureScreen> createState() => _RoleplayFeatureScreenState();
}

class _RoleplayFeatureScreenState extends State<RoleplayFeatureScreen> {
  static const String _labelDialogue = 'roleplay_dialogue';
  static const String _labelArtifact = 'artifact_feedback';

  final TextEditingController _chatController = TextEditingController();
  final TextEditingController _artifactController = TextEditingController();
  final TextEditingController _reflectionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _personaRoleController = TextEditingController();
  final TextEditingController _traitsController = TextEditingController();
  final TextEditingController _goalsController = TextEditingController();
  final TextEditingController _scenarioContextController =
      TextEditingController();

  final List<Map<String, String>> _messages = <Map<String, String>>[];
  final List<ChatTurn> _chatHistory = <ChatTurn>[];

  List<RoleplayScenario> _scenarios = [];
  RoleplayScenario? _selectedScenario;

  List<Course> _courses = [];
  Course? _selectedCourse;
  List<Assignment> _assignments = [];
  Assignment? _selectedAssignment;
  List<Participant> _participants = [];
  Participant? _selectedStudent;

  bool _isLoading = false;
  final bool _localLlmAvail = !kIsWeb;
  LlmType _selectedLLM = LlmType.CHATGPT;

  bool get _isTeacher => LocalStorageService.getUserRole() == UserRole.teacher;

  bool get _canSend =>
      !_isLoading &&
      _selectedScenario != null &&
      _selectedCourse != null &&
      _selectedAssignment != null &&
      _selectedStudent != null &&
      _hasKeyFor(_selectedLLM);

  @override
  void initState() {
    super.initState();
    _loadScenarios();
    _loadCourses();
  }

  @override
  void dispose() {
    _chatController.dispose();
    _artifactController.dispose();
    _reflectionController.dispose();
    _scrollController.dispose();
    _titleController.dispose();
    _personaRoleController.dispose();
    _traitsController.dispose();
    _goalsController.dispose();
    _scenarioContextController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    try {
      final courses = await LmsFactory.getLmsService().getUserCourses();
      if (!mounted) return;
      setState(() {
        _courses = courses;
      });
    } catch (_) {
      _showSnack('Failed to load courses.');
    }
  }

  Future<void> _selectCourse(Course? course) async {
    if (course == null) {
      setState(() {
        _selectedCourse = null;
        _selectedAssignment = null;
        _selectedStudent = null;
        _assignments = [];
        _participants = [];
      });
      return;
    }

    setState(() {
      _selectedCourse = course;
      _selectedAssignment = null;
      _selectedStudent = null;
      _assignments = [];
      _participants = [];
    });

    try {
      await course.refreshEssays();
      final participants = await LmsFactory.getLmsService()
          .getCourseParticipants(course.id.toString());
      if (!mounted) return;
      setState(() {
        _assignments = course.essays ?? [];
        _participants = participants;
        _selectedStudent = _resolveCurrentStudentFromList(participants) ??
            (participants.isNotEmpty ? participants.first : null);
      });
    } catch (_) {
      _showSnack('Failed to load assignments or participants.');
    }
  }

  void _loadScenarios() {
    final scenarios = RoleplayScenarioService.getScenarios();
    setState(() {
      _scenarios = scenarios;
      _selectedScenario ??= scenarios.isNotEmpty ? scenarios.first : null;
    });
  }

  bool _hasKeyFor(LlmType llm) {
    return (llm == LlmType.LOCAL &&
            LocalStorageService.getLocalLLMPath().isNotEmpty &&
            _localLlmAvail) ||
        LocalStorageService.userHasLlmKey(llm);
  }

  LLM? _createModel() {
    switch (_selectedLLM) {
      case LlmType.CHATGPT:
        final key = LocalStorageService.getOpenAIKey();
        return key.isEmpty ? null : OpenAiLLM(key);
      case LlmType.GROK:
        final key = LocalStorageService.getGrokKey();
        return key.isEmpty ? null : GrokLLM(key);
      case LlmType.PERPLEXITY:
        final key = LocalStorageService.getPerplexityKey();
        return key.isEmpty ? null : PerplexityLLM(key);
      case LlmType.DEEPSEEK:
        final key = LocalStorageService.getDeepseekKey();
        return key.isEmpty ? null : DeepseekLLM(key);
      case LlmType.LOCAL:
        final llmPath = LocalStorageService.getLocalLLMPath();
        return (llmPath.isEmpty || !_localLlmAvail) ? null : LocalLLMService();
    }
  }

  Participant? _resolveCurrentStudentFromList(List<Participant> participants) {
    final userId = int.tryParse(LocalStorageService.getUserId() ?? '');
    if (userId == null) return null;
    try {
      return participants.firstWhere((p) => p.id == userId);
    } catch (_) {
      return null;
    }
  }

  String _buildRoleplaySystemPrompt(RoleplayScenario scenario) {
    return '''
You are roleplaying as: ${scenario.personaRole}
Persona traits: ${scenario.personaTraits}
Persona goals: ${scenario.personaGoals}
Scenario context: ${scenario.scenarioContext}

Stay in character across the full session. Responses should be realistic and consistent with this persona.
You are supporting student learning. Do not provide full assignment answers or complete work for the student.
Use guided coaching, clarifying questions, actionable hints, and constructive feedback.
If the student shares an artifact, critique it and suggest improvements without rewriting the full final submission.
Use plain text only (no Markdown).
''';
  }

  bool _ensureReadyForInteraction() {
    if (_selectedScenario == null ||
        _selectedCourse == null ||
        _selectedAssignment == null ||
        _selectedStudent == null) {
      _showSnack('Select a course, assignment, student, and scenario first.');
      return false;
    }

    if (!_hasKeyFor(_selectedLLM)) {
      _showSnack(
          'Missing API key or local model for ${_selectedLLM.displayName}.');
      return false;
    }

    return true;
  }

  void _appendUserMessage(String text) {
    _messages.add({'sender': 'user', 'text': text});
    _chatHistory.add(ChatTurn(role: 'user', content: text));
  }

  void _appendAssistantMessage(String text) {
    _messages.add({'sender': 'bot', 'text': text});
    _chatHistory.add(ChatTurn(role: 'assistant', content: text));
  }

  Future<void> _runRoleplayInteraction({
    required String prompt,
    required String label,
    required String failureSnack,
  }) async {
    if (_isLoading || !_ensureReadyForInteraction()) return;

    final model = _createModel();
    if (model == null) {
      _showSnack('Unable to initialize ${_selectedLLM.displayName}.');
      return;
    }

    final reflection = _reflectionController.text.trim();

    setState(() {
      _isLoading = true;
      _appendUserMessage(prompt);
    });
    _scrollToBottom();

    try {
      final ctx = generateContext(
        permTokens:
            PermTokens(core: _buildRoleplaySystemPrompt(_selectedScenario!)),
        chatHistory: _chatHistory,
        userPrompt: prompt,
        llmContextSize: model.contextSize,
        maxOutputTokens: 500,
      );

      final response = await model.chat(context: ctx);
      if (!mounted) return;
      setState(() {
        _appendAssistantMessage(response);
        _isLoading = false;
      });
      _scrollToBottom();

      await _logInteraction(
        prompt: prompt,
        response: response,
        reflection: reflection,
        label: label,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showSnack(failureSnack);
    }
  }

  Future<void> _sendRoleplayMessage() async {
    final userPrompt = _chatController.text.trim();
    if (userPrompt.isEmpty) return;
    _chatController.clear();

    await _runRoleplayInteraction(
      prompt: userPrompt,
      label: _labelDialogue,
      failureSnack: 'Could not fetch roleplay response.',
    );
  }

  Future<void> _requestArtifactFeedback() async {
    final artifact = _artifactController.text.trim();
    if (artifact.isEmpty) {
      _showSnack('Paste your artifact content first.');
      return;
    }

    final prompt =
        'Provide guided feedback on this student artifact. Focus on strengths, risks, and next improvements.\n\nArtifact:\n$artifact';

    await _runRoleplayInteraction(
      prompt: prompt,
      label: _labelArtifact,
      failureSnack: 'Could not fetch feedback for your artifact.',
    );
  }

  Future<void> _logInteraction({
    required String prompt,
    required String response,
    required String reflection,
    required String label,
  }) async {
    final course = _selectedCourse;
    final assignment = _selectedAssignment;
    final student = _selectedStudent;
    if (course == null || assignment == null || student == null) return;

    try {
      final log = AiLog(
        course,
        assignment,
        student,
        prompt,
        response,
        _selectedLLM,
        reflection,
        '',
        label,
      );
      await AILoggingSingleton().addLog(log);
    } catch (_) {
      // Keep roleplay session functional if logging fails.
    }
  }

  void _saveScenario() {
    final title = _titleController.text.trim();
    final personaRole = _personaRoleController.text.trim();
    final traits = _traitsController.text.trim();
    final goals = _goalsController.text.trim();
    final context = _scenarioContextController.text.trim();

    if (title.isEmpty ||
        personaRole.isEmpty ||
        traits.isEmpty ||
        goals.isEmpty ||
        context.isEmpty) {
      _showSnack('Fill all persona and scenario fields.');
      return;
    }

    final scenario = RoleplayScenario(
      id: '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(9999)}',
      title: title,
      personaRole: personaRole,
      personaTraits: traits,
      personaGoals: goals,
      scenarioContext: context,
      createdAt: DateTime.now().toUtc(),
    );

    RoleplayScenarioService.upsertScenario(scenario);
    _titleController.clear();
    _personaRoleController.clear();
    _traitsController.clear();
    _goalsController.clear();
    _scenarioContextController.clear();
    _loadScenarios();
    _showSnack('Scenario saved.');
  }

  void _openLogs() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AiLogScreen()),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildTeacherView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Roleplay Persona Builder',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Scenario Title',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _personaRoleController,
          decoration: const InputDecoration(
            labelText: 'Persona Role (client, stakeholder, customer, etc.)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _traitsController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Persona Traits',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _goalsController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Persona Goals',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _scenarioContextController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Scenario Context',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _saveScenario,
          child: const Text('Save Roleplay Scenario'),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _openLogs,
            icon: const Icon(Icons.fact_check),
            label: const Text('View Roleplay/AI Logs In-App'),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Saved Scenarios',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (_scenarios.isEmpty)
          const Text('No scenarios saved yet.')
        else
          ..._scenarios.map(
            (scenario) => Card(
              child: ListTile(
                title: Text(scenario.title),
                subtitle:
                    Text('${scenario.personaRole} | ${scenario.personaGoals}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    RoleplayScenarioService.deleteScenario(scenario.id);
                    _loadScenarios();
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStudentView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 300,
                child: DropdownButtonFormField<Course>(
                  value: _selectedCourse,
                  decoration: const InputDecoration(
                    labelText: 'Course',
                    border: OutlineInputBorder(),
                  ),
                  items: _courses
                      .map(
                        (course) => DropdownMenuItem(
                          value: course,
                          child: Text(course.fullName),
                        ),
                      )
                      .toList(),
                  onChanged: _selectCourse,
                ),
              ),
              SizedBox(
                width: 300,
                child: DropdownButtonFormField<Assignment>(
                  value: _selectedAssignment,
                  decoration: const InputDecoration(
                    labelText: 'Assignment',
                    border: OutlineInputBorder(),
                  ),
                  items: _assignments
                      .map(
                        (assignment) => DropdownMenuItem(
                          value: assignment,
                          child: Text(assignment.name),
                        ),
                      )
                      .toList(),
                  onChanged: (assignment) {
                    setState(() {
                      _selectedAssignment = assignment;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 300,
                child: DropdownButtonFormField<Participant>(
                  value: _selectedStudent,
                  decoration: const InputDecoration(
                    labelText: 'Student (Log Attribution)',
                    border: OutlineInputBorder(),
                  ),
                  items: _participants
                      .map(
                        (participant) => DropdownMenuItem(
                          value: participant,
                          child: Text(participant.fullname),
                        ),
                      )
                      .toList(),
                  onChanged: (participant) {
                    setState(() {
                      _selectedStudent = participant;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 320,
                child: DropdownButtonFormField<RoleplayScenario>(
                  value: _selectedScenario,
                  decoration: const InputDecoration(
                    labelText: 'Roleplay Scenario',
                    border: OutlineInputBorder(),
                  ),
                  items: _scenarios
                      .map(
                        (scenario) => DropdownMenuItem(
                          value: scenario,
                          child: Text(scenario.title),
                        ),
                      )
                      .toList(),
                  onChanged: (scenario) {
                    setState(() {
                      _selectedScenario = scenario;
                      _messages.clear();
                      _chatHistory.clear();
                    });
                  },
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<LlmType>(
                  value: _selectedLLM,
                  decoration: const InputDecoration(
                    labelText: 'Model',
                    border: OutlineInputBorder(),
                  ),
                  items: LlmType.values.map((llm) {
                    final enabled = _hasKeyFor(llm);
                    return DropdownMenuItem(
                      value: llm,
                      enabled: enabled,
                      child: Text(
                        llm.displayName,
                        style: TextStyle(
                          color: enabled ? Colors.black87 : Colors.grey,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (llm) {
                    if (llm == null) return;
                    if (!_hasKeyFor(llm)) {
                      _showSnack('Missing API key for ${llm.displayName}.');
                      return;
                    }
                    setState(() {
                      _selectedLLM = llm;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        if (_selectedScenario != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  'Persona: ${_selectedScenario!.personaRole}\n'
                  'Traits: ${_selectedScenario!.personaTraits}\n'
                  'Goals: ${_selectedScenario!.personaGoals}',
                ),
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              final isUser = message['sender'] == 'user';
              return Align(
                alignment:
                    isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.blue.shade700 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    message['text'] ?? '',
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_isLoading) const LinearProgressIndicator(),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: _chatController,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Message the role persona',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _artifactController,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Artifact (writing/design/code) for feedback',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reflectionController,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reflection (optional, included in logs)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _canSend ? _sendRoleplayMessage : null,
                      child: const Text('Send Roleplay Message'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _canSend ? _requestArtifactFeedback : null,
                      child: const Text('Get Artifact Feedback'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _openLogs,
                    child: const Text('View Logs'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Roleplay',
        userprofileurl: LmsFactory.getLmsService().profileImage ?? '',
      ),
      body: _isTeacher ? _buildTeacherView() : _buildStudentView(),
    );
  }
}
