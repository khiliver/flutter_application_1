import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class AuthFormCard extends StatelessWidget {
  static const List<String> _studentCourseOptions = [
    'A.B. in Broadcasting',
    'A.B. in Journalism',
    'A.B. in Literature',
    'A.B. in Peace Studies',
    'A.B. in Philosophy',
    'A.B. in Sociology',
    'A.B. in Political Science',
    'Assoc. Dip. in Entrep. Development',
    'Asso. in Automotive Technology (Senior Tech)',
    'Asso. in Electronics Technology (Senior Tech)',
    'B.A. in Communication',
    'B.A. in English Language',
    'B. of Public Administration',
    'B.S. in Nursing',
    'B.S in Biology',
    'B.S in Chemistry',
    'B.S. in Computer Science',
    'B.S. in Information Technology',
    'B.S. in Meteorology',
    'Bachelor of Early Childhood Education',
    'Bachelor of Elementary Education',
    'Bachelor of Secondary Education, major in English',
    'Bachelor of Secondary Education, major in Filipino',
    'Bachelor of Secondary Education, major in Mathematics',
    'Bachelor of Secondary Education, major in Science',
    'Bachelor of Secondary Education, major in Social Studies',
    'Bachelor of Secondary Education, major in Values Education',
    'Bachelor of Culture & Arts Education, formerly BSED-non major',
    'Bachelor of Physical Education',
    'B.S. in Exercise & Sports Sciences',
    'BSESS major in Fitness & Sports Coaching',
    'BSESS major in Fitness & Sports Management',
    'B.S. in Chemical Engineering',
    'B.S. in Civil Engineering',
    'B.S. in Electrical Engineering',
    'B.S. in Geodetic Engineering',
    'B.S. in Mechanical Engineering',
    'B.S. in Mining Engineering',
    'B.S. in Architecture',
    'BTVTEd/BSIE, major in Drafting Technology',
    'BTVTEd/BSIE, major in Electrical Technology',
    'BTVTEd/BSIE, major in Food & Service Management',
    'BTVTEd/BSIE, major in Garments, Fashion & Design',
    'B.S. in Automotive Tech',
    'B.S. in Civil Technology',
    'B.S. in Electrical Technology',
    'B.S. in Food Technology',
    'B.S. in Mechanical Technology',
    'Bachelor in Industrial Design',
    'B.S. in in Economics',
    'B.S. in Accountancy',
    'B.S. in Entrepreneurship',
    'BSBA major in Financial Management',
    'BSBA major in Human Resources Management',
    'BSBA major in Management',
    'BSBA major in Marketing Management',
    'BSBA major in Microfinance',
    'BSBA major in Operation Management',
    'B.S in Psychology',
    'B.S. in Social Work',
    'Bachelor in Agricultural Technology',
    'BSED, major in Filipino',
    'BSED, major in Social Studies',
    'B.S. in Agricultural & Biosystems Education',
    'B.S. in Agribusiness',
    'B.S. in Agriculture (Ladderized Curriculum)',
    'B.S. in Agriculture, major in Animal Science',
    'B.S. in Agriculture, major in Crop Science',
    'B.S. in Agriculture, major in Agricultural Extension',
    'B.S. in Development Communication',
    'B.S. in Forestry',
    'BTVTE, major in Animal Production',
    'BTVTE, major in Agricultural Crop Production',
    'B.S. in Electronics Tech',
    'Bachelor in Elementary Education',
    'B.S. in Education, major in English',
    'Bachelor of Technology and livelihood Education, major in Home Economics',
    'Bachelor of Technology and livelihood Education, major in Information & Communication Technology',
    'B.S. in Information System',
    'B.S.I.T. major in Animation',
    'B.S. in Electronics Engineering',
    'B.S. in Computer Engineering',
    'B.S. in Education, major in Mathematics',
    'B.S. in Education, major in science',
    'B.S. in Fisheries',
    'B.S. in Fisheries (ETEEAP)',
    'B.S. in Agriculture (Certification)',
    'BUCE-Senior High School',
    'BUCE-ILS High School Department',
    'BUCE Lab. School Elementary Department',
    'Cert. in College Teaching',
    'Cert. in Professional Teaching',
    'Cert. in Physical Education',
    'Cert. in Automotive Technology (Lab AIde)',
    'Cert. in Electronics Technology (Lab Aide)',
    'Cert. as Asst. Electrician',
    'Cert. as Junior Electrical Craftsman',
    'Cert. as Senior Electrical Craftsman',
    'Cert. in Civil Craftsman',
    'Cert. of Proficiency',
    'Cert. in Entrepreneurship Marketing',
    'Cert. in Microfinance',
    'Cert. in Entrepreneurship Technology',
    'Diploma in Pre-School Education',
    'Doctor of Medicine',
    'Doctor of Dental Medicine',
    'Doctor of Veterinary Medicine',
    'Diploma in Automotive Technology (Junior Tech)',
    'Diploma in Electronics Technology (Junior Tech)',
    'Diploma in Agricultural Technology',
    'Ed.D. in Educational Leadership & Management',
    'Juris Doctor',
    'Mathematics Education',
    'Music Education',
    'M.A in Biology Education',
    'M.A in Chemistry Education',
    'M.A in Cultural Education',
    'M.A in Culture and Arts Education',
    'M.A in Educational Management',
    'M.A in Educational Leadership and Management',
    'M.A in Filipino Education',
    'M.A in General Science Education',
    'M.A in Science Education',
    'M.A in Guidance and Counseling',
    'M.A.I.E. major in Administration and Supervision',
    'M.A.I.E. major in Industrial Technology',
    'M.A.I.E. major in Technology and Livelihood Education',
    'M.A in Literature',
    'M.A in Mathematics Education',
    'M.A in Music Education',
    'M.A in Nursing',
    'M.A in Nursing Education',
    'M.A in Nursing, major in Nursing Education',
    'M.A in Physical Education',
    'M.A in Pre-School Education',
    'M.A in Reading Education',
    'M.A in Social Studies Education',
    'M.A in Public Administration',
    'MPA, major in Health Emergency and Disaster Management',
    'MPA, major in Public Procurement',
    'MA in Peace and Security Studies',
    'Master in Cooperative Management',
    'Master in Management',
    'MM, major in Human Resource Management',
    'Master in Entrepreneurship',
    'Master in Economics',
    'Master in Filipino',
    'Master in Information System',
    'Master in Local Government Management',
    'MS in Architecture',
    'MS in Biology',
    'MS in Sustainable Food System',
    'MST, major in Gen. Science',
    'M.A in English Education',
    'M.A in Social Studies Education',
    'Master of Public Administration',
    'MS in Agriculture, major in Agricultural Education',
    'MS in Agriculture, major in Agronomy',
    'MS in Agriculture, major in Animal Science',
    'MS in Agriculture, major in Crop Science',
    'Master in Rural Development',
    'Master in Science in Biodiversity & Environmental Management',
    'MS in Fisheries, Major in Aquaculture',
    'MS in Fisheries, major in Coastal Resource Management',
    'Ms in Fisheries Technology',
    'Reading Education',
    'Science Education',
    'Social Studies Education',
    'Two-Year Certificate in Entrepreneurship',
  ];

  final GlobalKey<ShadFormState> formKey;
  final bool isSignIn;
  final bool obscurePassword;
  final bool canCreateSuperAdmin;
  final String signUpCategory;
  final String signUpNonBuType;
  final String signUpPersonelType;
  final String signUpRole;
  final String signUpGender;
  final String? signUpAvatarPath;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController firstNameController;
  final TextEditingController middleNameController;
  final TextEditingController lastNameController;
  final TextEditingController contactNumberController;
  final TextEditingController birthdateController;
  final TextEditingController courseController;
  final TextEditingController collegeController;
  final TextEditingController departmentController;
  final TextEditingController schoolIdController;
  final TextEditingController employeeIdController;
  final TextEditingController addressController;
  final TextEditingController institutionOrSchoolController;
  final VoidCallback onForgotPassword;
  final VoidCallback onBackPressed;
  final VoidCallback onToggleObscurePassword;
  final VoidCallback onPickAvatar;
  final ValueChanged<int> onModeChanged;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onNonBuTypeChanged;
  final ValueChanged<String> onPersonelTypeChanged;
  final ValueChanged<String> onGenderChanged;
  final VoidCallback onSubmit;

  const AuthFormCard({
    super.key,
    required this.formKey,
    required this.isSignIn,
    required this.obscurePassword,
    required this.canCreateSuperAdmin,
    required this.signUpCategory,
    required this.signUpNonBuType,
    required this.signUpPersonelType,
    required this.signUpRole,
    required this.signUpGender,
    required this.signUpAvatarPath,
    required this.emailController,
    required this.passwordController,
    required this.firstNameController,
    required this.middleNameController,
    required this.lastNameController,
    required this.contactNumberController,
    required this.birthdateController,
    required this.courseController,
    required this.collegeController,
    required this.departmentController,
    required this.schoolIdController,
    required this.employeeIdController,
    required this.addressController,
    required this.institutionOrSchoolController,
    required this.onForgotPassword,
    required this.onBackPressed,
    required this.onToggleObscurePassword,
    required this.onPickAvatar,
    required this.onModeChanged,
    required this.onRoleChanged,
    required this.onCategoryChanged,
    required this.onNonBuTypeChanged,
    required this.onPersonelTypeChanged,
    required this.onGenderChanged,
    required this.onSubmit,
  });

  List<String> get _signUpRoleOptions =>
      canCreateSuperAdmin ? const ['User', 'Over All Admin'] : const ['User'];

  bool get _requiresCourseDetails {
    if (signUpRole.toLowerCase() != 'user') return false;
    return signUpCategory.toLowerCase() == 'student';
  }

  bool get _requiresDepartmentDetails {
    if (signUpRole.toLowerCase() != 'user') return false;
    return signUpCategory.toLowerCase() == 'personel';
  }

  bool get _requiresNonBuDetails {
    if (signUpRole.toLowerCase() != 'user') return false;
    return signUpCategory.toLowerCase() == 'non-bu';
  }

  InputDecoration _inputDecoration({
    required String hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
    String? label,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2D73E0), width: 1.5),
      ),
      filled: true,
      fillColor: const Color(0xFFF1F4FA),
      isDense: true,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? label,
    IconData? prefixIcon,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      decoration: _inputDecoration(
        hint: hint,
        label: label,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF223B64),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionLabel('Email'),
        _buildTextField(
          controller: emailController,
          hint: 'Enter your email',
          prefixIcon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            final email = value?.trim() ?? '';
            if (email.isEmpty) {
              return 'Please enter email';
            }
            if (!isSignIn && !email.toLowerCase().endsWith('@gmail.com')) {
              return 'Please use a Gmail address';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSignUpForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: CircleAvatar(
            radius: 38,
            backgroundImage:
                signUpAvatarPath != null && signUpAvatarPath!.isNotEmpty
                ? FileImage(File(signUpAvatarPath!))
                : null,
            child: signUpAvatarPath == null || signUpAvatarPath!.isEmpty
                ? const Icon(Icons.person, size: 36, color: Color(0xFF2D73E0))
                : null,
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: TextButton.icon(
            onPressed: onPickAvatar,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Upload profile picture'),
          ),
        ),
        const SizedBox(height: 10),
        _buildTextField(
          controller: firstNameController,
          hint: 'First name',
          validator: (value) {
            if ((value?.trim() ?? '').isEmpty) {
              return 'Please enter first name';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: middleNameController,
          hint: 'Middle name (optional)',
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: lastNameController,
          hint: 'Last name',
          validator: (value) {
            if ((value?.trim() ?? '').isEmpty) {
              return 'Please enter last name';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: contactNumberController,
          hint: 'Contact number',
          keyboardType: TextInputType.phone,
          validator: (value) {
            if ((value?.trim() ?? '').isEmpty) {
              return 'Please enter contact number';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: birthdateController,
          hint: 'Birthdate',
          readOnly: true,
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime(2000),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              birthdateController.text =
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            }
          },
          suffixIcon: const Icon(Icons.calendar_month_outlined, size: 20),
          validator: (value) {
            if ((value?.trim() ?? '').isEmpty) {
              return 'Please select birthdate';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: signUpGender,
          decoration: _inputDecoration(hint: 'Gender', label: 'Gender'),
          items:
              const [
                    'Male',
                    'Female',
                    'Cisgender',
                    'Transgender',
                    'Gender Queer',
                    'Non-Binary',
                    'Prefer not to say',
                  ]
                  .map(
                    (gender) =>
                        DropdownMenuItem(value: gender, child: Text(gender)),
                  )
                  .toList(),
          onChanged: (value) {
            if (value != null) {
              onGenderChanged(value);
            }
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: signUpRole,
          decoration: _inputDecoration(hint: 'Role', label: 'Role'),
          items: _signUpRoleOptions
              .map((role) => DropdownMenuItem(value: role, child: Text(role)))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              onRoleChanged(value);
            }
          },
        ),
        if (signUpRole.toLowerCase() == 'user') ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: signUpCategory,
            decoration: _inputDecoration(hint: 'User type', label: 'User Type'),
            items: const ['Student', 'Personel', 'Non-BU']
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onCategoryChanged(value);
              }
            },
          ),
        ],
        if (_requiresNonBuDetails) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: signUpNonBuType,
            decoration: _inputDecoration(
              hint: 'Non-BU type',
              label: 'Non-BU Type',
            ),
            items:
                const ['Student', 'Non-academic Based', 'Out of School Youth']
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
            onChanged: (value) {
              if (value != null) {
                onNonBuTypeChanged(value);
              }
            },
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: addressController,
            hint: 'Address',
            validator: (value) {
              if ((value?.trim() ?? '').isEmpty) {
                return 'Please enter address';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: institutionOrSchoolController,
            hint: 'Institution or school',
            validator: (value) {
              if ((value?.trim() ?? '').isEmpty) {
                return 'Please enter institution or school';
              }
              return null;
            },
          ),
        ],
        if (_requiresCourseDetails) ...[
          const SizedBox(height: 12),
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              final query = textEditingValue.text.trim().toLowerCase();
              if (query.isEmpty) {
                return _studentCourseOptions.take(8);
              }
              return _studentCourseOptions.where(
                (c) => c.toLowerCase().contains(query),
              );
            },
            displayStringForOption: (option) => option,
            onSelected: (selection) => courseController.text = selection,
            fieldViewBuilder:
                (context, textController, focusNode, onFieldSubmitted) {
                  // Keep using the shared controller so the rest of the form reads the value.
                  textController.text = courseController.text;
                  textController.selection = courseController.selection;
                  textController.addListener(() {
                    courseController.text = textController.text;
                  });
                  return TextFormField(
                    controller: textController,
                    focusNode: focusNode,
                    decoration: _inputDecoration(
                      hint: 'Course',
                      label: 'Course',
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Please select a course';
                      }
                      return null;
                    },
                  );
                },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 240,
                      maxWidth: 420,
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final String option = options.elementAt(index);
                        return InkWell(
                          onTap: () => onSelected(option),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            child: Text(option),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: schoolIdController,
            hint: 'School ID',
            validator: (value) {
              if ((value?.trim() ?? '').isEmpty) {
                return 'Please enter school ID';
              }
              return null;
            },
          ),
        ],
        if (_requiresDepartmentDetails) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: signUpPersonelType,
            decoration: _inputDecoration(
              hint: 'Personel type',
              label: 'Personel Type',
            ),
            items: const ['Faculty', 'Non-teaching Personel']
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onPersonelTypeChanged(value);
              }
            },
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: collegeController,
            hint: signUpPersonelType == 'Faculty'
                ? 'College'
                : 'Unit/Auxiliary',
            validator: (value) {
              if ((value?.trim() ?? '').isEmpty) {
                final fieldName = signUpPersonelType == 'Faculty'
                    ? 'college'
                    : 'unit/auxiliary';
                return 'Please enter $fieldName';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: departmentController,
            hint: signUpPersonelType == 'Faculty' ? 'Department' : 'Offices',
            validator: (value) {
              if ((value?.trim() ?? '').isEmpty) {
                final fieldName = signUpPersonelType == 'Faculty'
                    ? 'department'
                    : 'offices';
                return 'Please enter $fieldName';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: employeeIdController,
            hint: 'Employee ID',
            validator: (value) {
              if ((value?.trim() ?? '').isEmpty) {
                return 'Please enter employee ID';
              }
              return null;
            },
          ),
        ],
        const SizedBox(height: 12),
        _buildTextField(
          controller: emailController,
          hint: 'Email',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if ((value?.trim() ?? '').isEmpty) {
              return 'Please enter email';
            }
            return null;
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A101828),
              blurRadius: 28,
              offset: Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double minHeight = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : MediaQuery.of(context).size.height;
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
                child: ShadForm(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: onBackPressed,
                          icon: Icon(
                            Icons.chevron_left_rounded,
                            color: const Color(0xFF2D73E0),
                            size: 26,
                          ),
                          tooltip: 'Back',
                        ),
                      ),
                      Image.asset(
                        isSignIn
                            ? 'assets/AskRisaavatarwelcomeback.png'
                            : 'assets/AskRisaavatarwelcomeback.png',
                        height: 160,
                        fit: BoxFit.scaleDown,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            isSignIn
                                ? 'assets/AskRisaavatarwelcomeback.png'
                                : 'assets/AskRisaavatarwelcomeback.png',
                            height: 250,
                            fit: BoxFit.scaleDown,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (context, error, stackTrace) {
                              return const SizedBox(
                                height: 160,
                                child: Center(
                                  child: Icon(
                                    Icons.support_agent,
                                    size: 86,
                                    color: Color(0xFF2D73E0),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isSignIn ? 'Welcome Back!' : 'Create Account',
                        style: const TextStyle(
                          fontSize: 36,
                          height: 1.0,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B3763),
                        ),
                      ),
                      const SizedBox(height: 18),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: isSignIn
                            ? _buildSignInForm(context)
                            : _buildSignUpForm(context),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: passwordController,
                        hint: isSignIn
                            ? 'Enter your password'
                            : 'Create a password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: obscurePassword,
                        suffixIcon: IconButton(
                          onPressed: onToggleObscurePassword,
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 20,
                          ),
                        ),
                        validator: (value) {
                          final password = value?.trim() ?? '';
                          if (password.isEmpty) {
                            return 'Please enter password';
                          }
                          if (!isSignIn && password.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: onSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D73E0),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: Text(isSignIn ? 'Sign In' : 'Sign Up'),
                        ),
                      ),
                      if (isSignIn) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: onForgotPassword,
                            child: const Text('Forgot Password?'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isSignIn
                                ? 'Don\'t have an account? '
                                : 'Already have an account? ',
                            style: const TextStyle(
                              color: Color(0xFF8A97AF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => onModeChanged(isSignIn ? 1 : 0),
                            child: Text(
                              isSignIn ? 'Sign Up' : 'Sign In',
                              style: const TextStyle(
                                color: Color(0xFF2D73E0),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
