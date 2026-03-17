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
import 'package:learninglens_app/beans/workflow_support.dart';

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
                                : Column(
                                    children: [
                                      Expanded(flex: 1, child: _buildExpandedRequirementCards()),
                                      const SizedBox(height: 8),
                                      Expanded(
                                        flex: 2,
                                        child: isMoodle()
                                            ? _buildMoodleContent()
                                            : _buildGoogleContent(),
                                      ),
                                    ],
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

  // EDU-LENSE 2026 SPRING ADDITIONS -----------------------------------------
  // These cards surface the newly expanded requirements in the assessment view
  // without removing existing quiz functionality.
  Widget _buildExpandedRequirementCards() {
    final feedbackConfig = const EvaluationFeedbackConfig();
    final visualAssets = const [
      VisualMaterialAsset(
        id: 'assessment-visual-1',
        title: 'Assignment Diagram / Annotated Example',
        assetType: 'annotated-example',
        sourceLabel: 'teacher-uploaded',
        note: 'Intended for image-rich instructions, feedback artifacts, and scenario cards.',
      ),
      VisualMaterialAsset(
        id: 'assessment-visual-2',
        title: 'Roleplay Avatar / Scenario Asset',
        assetType: 'avatar',
        sourceLabel: 'university-contained',
        note: 'Reserved for secure image generation or curated classroom visuals.',
      ),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Assessment-Aware Guidance / AI Literacy',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  const Text(
                    'Added for this semester: embedded micro-reflection prompts, integrity nudges, and clearer differentiation between AI suggestions, student decisions, and student-authored work.',
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Teacher-Controlled Qualitative Feedback',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text('Tone: ${feedbackConfig.tone}'),
                  Text('Voice: ${feedbackConfig.voice}'),
                  Text('Detail level: ${feedbackConfig.detailLevel}'),
                  Text('Rubric aligned: ${feedbackConfig.rubricAligned ? 'Yes' : 'No'}'),
                  Text('Criteria referenced: ${feedbackConfig.criteriaReferenced ? 'Yes' : 'No'}'),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Visual Materials / Image Integration',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  const Text(
                    'Images are now treated as first-class instructional assets that can be embedded into assignments, activities, and feedback artifacts rather than purely decorative content.',
                  ),
                  const SizedBox(height: 8),
                  ...visualAssets.map((asset) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: const Icon(Icons.image_outlined),
                        title: Text(asset.title),
                        subtitle: Text('${asset.assetType} • ${asset.sourceLabel}\n${asset.note}'),
                      )),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rubrics / Export Readiness',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  const Text(
                    'This additive panel flags the semester requirements for stronger rubric templates, cleaner formatting, consistency checks, and classroom-ready exports.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodleContent() {
    return selectedQuiz == null && widget.quizID == 0
        ? const Center(child: Text('Select a quiz to view details'))
        : ViewQuiz(quizId: selectedQuiz?.id ?? widget.quizID);
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
