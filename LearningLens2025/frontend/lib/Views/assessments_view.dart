import "package:flutter/material.dart";
import 'package:learninglens_app/Api/lms/enum/lms_enum.dart';
import "package:learninglens_app/Api/lms/factory/lms_factory.dart";
import 'package:learninglens_app/Api/lms/google_classroom/google_lms_service.dart';
import 'package:learninglens_app/beans/g_question_form_data.dart';
import 'package:learninglens_app/beans/quiz.dart';
import 'package:learninglens_app/beans/course.dart';
import "package:learninglens_app/Controller/custom_appbar.dart";
import 'package:learninglens_app/content_carousel.dart';
import 'package:learninglens_app/services/local_storage_service.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import "package:learninglens_app/Views/view_quiz.dart";
import 'package:learninglens_app/Views/edulense_requirement_widgets.dart';

class AssessmentsView extends StatefulWidget {
  AssessmentsView({super.key, this.quizID = 0, this.courseID = 0});

  final int quizID;
  final int? courseID;

  @override
  _AssessmentsState createState() => _AssessmentsState();
}

class _AssessmentsState extends State<AssessmentsView> {
  late Future<List<Quiz>?> quizzes;
  Quiz? selectedQuiz;
  List<Map<String, dynamic>> questionsData = [];
  Future<FormData>? _formDataFuture;
  GoogleLmsService googleLmsService = GoogleLmsService();

  // Added for Spring 2026 evaluation requirements: these teacher-configurable
  // qualitative feedback controls surface tone, voice, detail, and alignment
  // choices without removing the existing assessment viewer behavior.
  String _selectedFeedbackTone = 'Supportive';
  String _selectedFeedbackVoice = 'Instructor coach';
  String _selectedFeedbackDetail = 'Balanced';
  String _selectedFeedbackMode = 'Supportive + critical blend';

  @override
  void initState() {
    super.initState();
    _refreshQuizzes();
  }

  // Check if Moodle is selected
  bool isMoodle() {
    return LocalStorageService.getSelectedClassroom() == LmsType.MOODLE;
  }

  // Method to refresh quizzes
  void _refreshQuizzes() {
    setState(() {
      quizzes = getAllQuizzes();
    });
  }

  // Added requirement helper: determine whether the current assessment has a
  // rubric-like structure available so the feedback summary can advertise
  // rubric-aligned vs criteria-referenced behavior.
  bool get _supportsRubricAlignment => selectedQuiz?.description?.isNotEmpty ?? false;

  Widget _buildEvaluationRequirementPanel() {
    return Column(
      children: [
        EduLenseEvaluationConfigurationCard(
          tone: _selectedFeedbackTone,
          voice: _selectedFeedbackVoice,
          detailLevel: _selectedFeedbackDetail,
          feedbackMode: _selectedFeedbackMode,
          supportsRubricAlignment: _supportsRubricAlignment,
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Qualitative Feedback Controls',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedFeedbackTone,
                  decoration: const InputDecoration(
                    labelText: 'Tone',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Supportive', child: Text('Supportive')),
                    DropdownMenuItem(value: 'Neutral', child: Text('Neutral')),
                    DropdownMenuItem(value: 'Direct', child: Text('Direct')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedFeedbackTone = value);
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedFeedbackVoice,
                  decoration: const InputDecoration(
                    labelText: 'Voice',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Instructor coach', child: Text('Instructor coach')),
                    DropdownMenuItem(value: 'Academic reviewer', child: Text('Academic reviewer')),
                    DropdownMenuItem(value: 'Encouraging mentor', child: Text('Encouraging mentor')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedFeedbackVoice = value);
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedFeedbackDetail,
                  decoration: const InputDecoration(
                    labelText: 'Level of detail',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Brief', child: Text('Brief')),
                    DropdownMenuItem(value: 'Balanced', child: Text('Balanced')),
                    DropdownMenuItem(value: 'Detailed', child: Text('Detailed')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedFeedbackDetail = value);
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedFeedbackMode,
                  decoration: const InputDecoration(
                    labelText: 'Feedback style',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Supportive + critical blend', child: Text('Supportive + critical blend')),
                    DropdownMenuItem(value: 'Mostly supportive', child: Text('Mostly supportive')),
                    DropdownMenuItem(value: 'Mostly critical', child: Text('Mostly critical')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedFeedbackMode = value);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Assessments',
        onRefresh: _refreshQuizzes,
        userprofileurl: LmsFactory.getLmsService().profileImage ?? '',
      ),
      body: Column(
        children: [
          Row(children: [
            Padding(
                padding: const EdgeInsets.all(4.0),
                child: CreateButton('assessment'))
          ]),
          Expanded(
            child: FutureBuilder<List<Quiz>?>(
              future: quizzes,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading quizzes'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No quizzes found'));
                } else {
                  final quizList = snapshot.data!;

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              margin: EdgeInsets.all(8.0),
                              child: ListView.builder(
                                itemCount: quizList.length,
                                itemBuilder: (context, index) {
                                  final quiz = quizList[index];
                                  final activeCourse =
                                      getCourse(quiz.coursedId);
                                  if (quiz.id == widget.quizID) {
                                    selectedQuiz = quiz;
                                  }

                                  return ListTile(
                                    title: Text(
                                        '${quiz.name} (${activeCourse.shortName}${activeCourse.courseId})'),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            'Due: ${quiz.timeClose == null ? "No due date set" : Course.dateFormatted(quiz.timeClose!)}'),
                                      ],
                                    ),
                                    tileColor: selectedQuiz == quiz
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.1)
                                        : null,
                                    onTap: () {
                                      setState(() {
                                        selectedQuiz = quiz;
                                        if (!isMoodle()) {
                                          _formDataFuture = googleLmsService
                                              .getAssignmentFormQuestions(
                                                  quiz.coursedId.toString(),
                                                  quiz.id.toString());
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: selectedQuiz == null
                                ? Center(
                                    child:
                                        Text('Select a quiz to view details'))
                                : SingleChildScrollView(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        // Added requirement panel: teacher-facing
                                        // qualitative feedback controls and summary.
                                        _buildEvaluationRequirementPanel(),
                                        const SizedBox(height: 12),
                                        isMoodle()
                                            ? _buildMoodleContent()
                                            : _buildGoogleContent(),
                                      ],
                                    ),
                                  ),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodleContent() {
    return selectedQuiz == null && widget.quizID == 0
        ? Center(child: Text('Select a quiz to view details'))
        : SizedBox(
            height: 700,
            child: ViewQuiz(quizId: selectedQuiz?.id ?? widget.quizID),
          );
  }

  Widget _buildGoogleContent() {
    return FutureBuilder<FormData>(
      future: _formDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData && snapshot.data!.questions.isNotEmpty) {
          return DynamicForm(formData: snapshot.data!);
        } else {
          return Center(child: Text('No questions found in the Google Form.'));
        }
      },
    );
  }
}

Future<List<Quiz>> getAllQuizzes() async {
  print("Getting all quizzes");
  List<Quiz> result = [];
  for (Course c in LmsFactory.getLmsService().courses ?? []) {
    result.addAll(c.quizzes ?? []);
  }
  return result;
}

Course getCourse(int? courseID) {
  for (Course c in LmsFactory.getLmsService().courses ?? []) {
    if (c.id == courseID) {
      return c;
    }
  }
  throw "No course found.";
}

class DynamicForm extends StatelessWidget {
  final FormData formData;

  const DynamicForm({super.key, required this.formData});

  String _getQuestionType(List<String> options) {
    if (options.isEmpty) {
      return 'Short Answer';
    } else if (options.length == 2) {
      return 'True/False';
    } else {
      return 'Multiple Choice';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  formData.title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Start Date: ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(formData.startDate ?? 'N/A'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('End Date: ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(formData.endDate ?? 'N/A'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Form URL: ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          GestureDetector(
                            onTap: () async {
                              if (formData.formUrl != null) {
                                final Uri url = Uri.parse(formData.formUrl!);
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Cannot launch URL')),
                                  );
                                }
                              }
                            },
                            child: Text(
                              formData.formUrl ?? 'N/A',
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          if (formData.formUrl != null) ...[
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: formData.formUrl!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('URL copied to clipboard')),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Status: ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(formData.status ?? 'N/A'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 20,
                          dataRowHeight: 60,
                          headingRowColor: MaterialStateProperty.all(
                              Colors.blueAccent.withOpacity(0.1)),
                          border: TableBorder.all(
                            color: Colors.grey,
                            width: 1.0,
                          ),
                          columns: const [
                            DataColumn(
                              label: Center(
                                child: Text('Question No.',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            DataColumn(
                              label: Center(
                                child: Text('Question',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            DataColumn(
                              label: Center(
                                child: Text('Type',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            DataColumn(
                              label: Center(
                                child: Text('Options',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                          rows: formData.questions.asMap().entries.map((entry) {
                            int index = entry.key + 1;
                            QuestionData questionData = entry.value;
                            return DataRow(cells: [
                              DataCell(Text('$index')),
                              DataCell(
                                SizedBox(
                                  width: 400,
                                  child: Text(
                                    questionData.question,
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  _getQuestionType(questionData.options),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 300,
                                  child: Text(
                                    questionData.options.isEmpty
                                        ? 'N/A'
                                        : questionData.options.join(', '),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                              ),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
