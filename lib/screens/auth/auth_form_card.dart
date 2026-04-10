import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants.dart';

class AuthFormCard extends StatelessWidget {
  final GlobalKey<ShadFormState> formKey;
  final bool isSignIn;
  final bool obscurePassword;
  final bool canCreateSuperAdmin;
  final String signUpCategory;
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
  final VoidCallback onForgotPassword;
  final VoidCallback onToggleObscurePassword;
  final VoidCallback onPickAvatar;
  final ValueChanged<int> onModeChanged;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onGenderChanged;
  final VoidCallback onSubmit;

  const AuthFormCard({
    super.key,
    required this.formKey,
    required this.isSignIn,
    required this.obscurePassword,
    required this.canCreateSuperAdmin,
    required this.signUpCategory,
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
    required this.onForgotPassword,
    required this.onToggleObscurePassword,
    required this.onPickAvatar,
    required this.onModeChanged,
    required this.onRoleChanged,
    required this.onCategoryChanged,
    required this.onGenderChanged,
    required this.onSubmit,
  });

  List<String> get _signUpRoleOptions =>
      canCreateSuperAdmin ? const ['User', 'Super Admin'] : const ['User'];

  bool get _requiresAcademicDetails {
    if (signUpRole.toLowerCase() != 'user') return false;
    final normalizedType = signUpCategory.toLowerCase();
    return normalizedType == 'student' || normalizedType == 'personel';
  }

  bool get _requiresCourseDetails {
    if (signUpRole.toLowerCase() != 'user') return false;
    return signUpCategory.toLowerCase() == 'student';
  }

  @override
  Widget build(BuildContext context) {
    return ShadForm(
      key: formKey,
      child: Center(
        child: ShadCard(
          width: kFormElementWidth + 32,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Research and Information Search Assistant',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.blueAccent),
              ),
              const SizedBox(height: 8),
              Image.asset('assets/Risa_logo.png', height: 78),
              const SizedBox(height: 24),
              ToggleButtons(
                isSelected: [isSignIn, !isSignIn],
                onPressed: onModeChanged,
                selectedColor: Colors.white,
                fillColor: Colors.blue,
                borderColor: Colors.blue,
                selectedBorderColor: Colors.blue,
                borderRadius: BorderRadius.circular(4),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Sign In'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Sign Up'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: Column(
                  key: ValueKey<bool>(isSignIn),
                  children: [
                    if (!isSignIn) ...[
                      SizedBox(
                        width: kFormElementWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.center,
                              child: CircleAvatar(
                                radius: 36,
                                backgroundImage:
                                    signUpAvatarPath != null &&
                                        signUpAvatarPath!.isNotEmpty
                                    ? FileImage(File(signUpAvatarPath!))
                                    : null,
                                child:
                                    signUpAvatarPath == null ||
                                        signUpAvatarPath!.isEmpty
                                    ? const Icon(Icons.person, size: 34)
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.center,
                              child: ShadButton.ghost(
                                onPressed: onPickAvatar,
                                leading: const Icon(Icons.photo_library),
                                child: const Text('Upload Profile Picture'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ShadInputFormField(
                              controller: firstNameController,
                              placeholder: const Text('First Name'),
                              validator: (v) {
                                if (!isSignIn && v.trim().isEmpty) {
                                  return 'Please enter first name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            ShadInputFormField(
                              controller: middleNameController,
                              placeholder: const Text('Middle Name (Optional)'),
                            ),
                            const SizedBox(height: 16),
                            ShadInputFormField(
                              controller: lastNameController,
                              placeholder: const Text('Last Name'),
                              validator: (v) {
                                if (!isSignIn && v.trim().isEmpty) {
                                  return 'Please enter last name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            ShadInputFormField(
                              controller: contactNumberController,
                              placeholder: const Text('Contact Number'),
                              validator: (v) {
                                if (!isSignIn && v.trim().isEmpty) {
                                  return 'Please enter contact number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            ShadInput(
                              controller: birthdateController,
                              placeholder: const Text('Birthdate'),
                              readOnly: true,
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime(2000),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  birthdateController.text = date
                                      .toLocal()
                                      .toString()
                                      .split(' ')[0];
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              initialValue: signUpGender,
                              decoration: const InputDecoration(
                                labelText: 'Gender',
                              ),
                              items: ['Male', 'Female', 'Other']
                                  .map(
                                    (gender) => DropdownMenuItem(
                                      value: gender,
                                      child: Text(gender),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  onGenderChanged(v);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: kFormElementWidth,
                        child: DropdownButtonFormField<String>(
                          initialValue: signUpRole,
                          decoration: const InputDecoration(labelText: 'Role'),
                          items: _signUpRoleOptions
                              .map(
                                (role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(role),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              onRoleChanged(v);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (signUpRole.toLowerCase() == 'user') ...[
                        SizedBox(
                          width: kFormElementWidth,
                          child: DropdownButtonFormField<String>(
                            initialValue: signUpCategory,
                            decoration: const InputDecoration(
                              labelText: 'User Type',
                            ),
                            items: const ['Student', 'Personel', 'Non-BU']
                                .map(
                                  (u) => DropdownMenuItem(
                                    value: u,
                                    child: Text(u),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                onCategoryChanged(v);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_requiresCourseDetails) ...[
                          SizedBox(
                            width: kFormElementWidth,
                            child: ShadInputFormField(
                              controller: courseController,
                              placeholder: const Text('Course'),
                              validator: (v) {
                                if (_requiresCourseDetails &&
                                    v.trim().isEmpty) {
                                  return 'Please enter course';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_requiresAcademicDetails) ...[
                          SizedBox(
                            width: kFormElementWidth,
                            child: ShadInputFormField(
                              controller: collegeController,
                              placeholder: const Text('College'),
                              validator: (v) {
                                if (_requiresAcademicDetails &&
                                    v.trim().isEmpty) {
                                  return 'Please enter college';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: kFormElementWidth,
                            child: ShadInputFormField(
                              controller: departmentController,
                              placeholder: const Text('Department'),
                              validator: (v) {
                                if (_requiresAcademicDetails &&
                                    v.trim().isEmpty) {
                                  return 'Please enter department';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ],
                    SizedBox(
                      width: kFormElementWidth,
                      child: ShadInputFormField(
                        controller: emailController,
                        placeholder: const Text('Email'),
                        validator: (v) {
                          if (v.trim().isEmpty) {
                            return 'Please enter email';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: kFormElementWidth,
                      child: Stack(
                        children: [
                          ShadInputFormField(
                            controller: passwordController,
                            placeholder: const Text('Password'),
                            obscureText: obscurePassword,
                            validator: (v) {
                              final password = v.trim();
                              if (password.isEmpty) {
                                return 'Please enter password';
                              }
                              if (!isSignIn && password.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              tooltip: obscurePassword
                                  ? 'Show password'
                                  : 'Hide password',
                              onPressed: onToggleObscurePassword,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSignIn) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ShadButton.link(
                          onPressed: onForgotPassword,
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else
                      const SizedBox(height: 24),
                    ShadButton.outline(
                      onPressed: onSubmit,
                      leading: Icon(
                        isSignIn ? Icons.login : Icons.app_registration,
                      ),
                      child: Text(isSignIn ? 'Login' : 'Register'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
