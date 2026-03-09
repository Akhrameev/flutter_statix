// sample_code.dart - Test file for various maintainability index scores

/// Excellent Maintainability (CMI: ~90-100)
/// Simple, single-purpose function
int add(int a, int b) {
  return a + b;
}

/// Excellent Maintainability (CMI: ~85-95)
/// Simple getter with minimal logic
String getFormattedName(String firstName, String lastName) {
  return '$firstName $lastName';
}

/// Good Maintainability (CMI: ~70-84)
/// Moderate complexity with single responsibility
bool isValidEmail(String email) {
  if (email.isEmpty) return false;

  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return emailRegex.hasMatch(email) && email.length <= 254;
}

/// Good Maintainability (CMI: ~75-85)
/// Simple loop with basic condition
List<int> getEvenNumbers(List<int> numbers) {
  List<int> evenNumbers = [];

  for (int number in numbers) {
    if (number % 2 == 0) {
      evenNumbers.add(number);
    }
  }

  return evenNumbers;
}

/// Moderate Maintainability (CMI: ~50-69)
/// Multiple conditions and moderate nesting
String categorizeAge(int age) {
  if (age < 0) {
    return 'Invalid age';
  } else if (age < 13) {
    return 'Child';
  } else if (age < 20) {
    return 'Teenager';
  } else if (age < 60) {
    return 'Adult';
  } else {
    return 'Senior';
  }
}

/// Moderate Maintainability (CMI: ~55-65)
/// Multiple return statements and boolean expressions
String validatePassword(String password) {
  if (password.length < 8) {
    return 'Password too short';
  }

  if (!password.contains(RegExp(r'[A-Z]'))) {
    return 'Password must contain uppercase letter';
  }

  if (!password.contains(RegExp(r'[a-z]'))) {
    return 'Password must contain lowercase letter';
  }

  if (!password.contains(RegExp(r'[0-9]'))) {
    return 'Password must contain number';
  }

  if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
    return 'Password must contain special character';
  }

  return 'Valid password';
}

/// Poor Maintainability (CMI: ~25-49)
/// High nesting, multiple conditions, complex logic
Map<String, dynamic> processUserData(Map<String, dynamic> userData) {
  Map<String, dynamic> result = {};

  if (userData.containsKey('name') && userData['name'] != null) {
    if (userData['name'].toString().isNotEmpty) {
      result['name'] = userData['name'].toString().trim();

      if (userData.containsKey('email') && userData['email'] != null) {
        String email = userData['email'].toString().toLowerCase();

        if (email.contains('@') && email.contains('.')) {
          result['email'] = email;

          if (userData.containsKey('age') && userData['age'] != null) {
            try {
              int age = int.parse(userData['age'].toString());

              if (age >= 0 && age <= 150) {
                result['age'] = age;

                if (userData.containsKey('preferences')) {
                  if (userData['preferences'] is Map) {
                    result['preferences'] = userData['preferences'];
                  } else {
                    result['preferences'] = {};
                  }
                } else {
                  result['preferences'] = {};
                }
              } else {
                result['error'] = 'Invalid age range';
                return result;
              }
            } catch (e) {
              result['error'] = 'Invalid age format';
              return result;
            }
          } else {
            result['error'] = 'Age is required';
            return result;
          }
        } else {
          result['error'] = 'Invalid email format';
          return result;
        }
      } else {
        result['error'] = 'Email is required';
        return result;
      }
    } else {
      result['error'] = 'Name cannot be empty';
      return result;
    }
  } else {
    result['error'] = 'Name is required';
    return result;
  }

  return result;
}

/// Poor Maintainability (CMI: ~30-45)
/// Complex switch statement with nested conditions
String calculateShippingCost(String country, double weight, bool isPriority, bool isFragile) {
  double baseCost = 0.0;
  double weightMultiplier = 1.0;
  double priorityMultiplier = 1.0;
  double fragileMultiplier = 1.0;

  switch (country.toLowerCase()) {
    case 'usa':
    case 'canada':
      baseCost = 10.0;
      if (weight > 5.0) {
        weightMultiplier = 1.5;
        if (weight > 10.0) {
          weightMultiplier = 2.0;
          if (weight > 20.0) {
            weightMultiplier = 3.0;
          }
        }
      }
      break;

    case 'uk':
    case 'germany':
    case 'france':
      baseCost = 15.0;
      if (weight > 3.0) {
        weightMultiplier = 1.8;
        if (weight > 8.0) {
          weightMultiplier = 2.5;
        }
      }
      break;

    case 'japan':
    case 'australia':
      baseCost = 25.0;
      if (weight > 2.0) {
        weightMultiplier = 2.0;
      }
      break;

    default:
      baseCost = 30.0;
      weightMultiplier = 2.5;
  }

  if (isPriority) {
    priorityMultiplier = 1.5;
    if (country.toLowerCase() == 'usa' || country.toLowerCase() == 'canada') {
      priorityMultiplier = 1.3;
    }
  }

  if (isFragile) {
    fragileMultiplier = 1.25;
    if (weight > 10.0) {
      fragileMultiplier = 1.5;
    }
  }

  double totalCost = baseCost * weightMultiplier * priorityMultiplier * fragileMultiplier;
  return '\$${totalCost.toStringAsFixed(2)}';
}

/// Legacy Code (CMI: ~0-24)
/// Extremely complex, deeply nested, multiple responsibilities
class LegacyProcessor {
  Map<String, dynamic> processComplexBusinessLogic(
      List<Map<String, dynamic>> inputData,
      Map<String, String> config,
      bool enableLogging,
      String outputFormat
      ) {
    Map<String, dynamic> finalResult = {};
    List<String> errors = [];
    List<String> warnings = [];
    int successCount = 0;
    int errorCount = 0;

    try {
      if (inputData.isNotEmpty) {
        for (int i = 0; i < inputData.length; i++) {
          Map<String, dynamic> item = inputData[i];

          if (item.isNotEmpty) {
            try {
              if (item.containsKey('type') && item['type'] != null) {
                String type = item['type'].toString().toLowerCase();

                if (type == 'user') {
                  if (item.containsKey('data') && item['data'] is Map) {
                    Map<String, dynamic> userData = item['data'];

                    if (userData.containsKey('id') && userData['id'] != null) {
                      try {
                        int userId = int.parse(userData['id'].toString());

                        if (userId > 0) {
                          if (userData.containsKey('profile')) {
                            Map<String, dynamic> profile = userData['profile'];

                            if (profile.isNotEmpty) {
                              if (profile.containsKey('name') && profile['name'] != null) {
                                String name = profile['name'].toString().trim();

                                if (name.isNotEmpty && name.length >= 2) {
                                  if (profile.containsKey('email')) {
                                    String email = profile['email'].toString().toLowerCase();

                                    if (email.contains('@') && email.contains('.') &&
                                        email.length > 5 && email.length < 100) {

                                      if (profile.containsKey('settings')) {
                                        Map<String, dynamic> settings = profile['settings'];

                                        bool isActive = settings['active'] == true;
                                        bool hasPermissions = settings['permissions'] != null;
                                        String role = settings['role']?.toString() ?? 'user';

                                        if (isActive && hasPermissions) {
                                          if (role == 'admin' || role == 'moderator' || role == 'user') {
                                            Map<String, dynamic> processedUser = {
                                              'id': userId,
                                              'name': name,
                                              'email': email,
                                              'role': role,
                                              'active': isActive,
                                              'processed_at': DateTime.now().toIso8601String(),
                                            };

                                            if (config.containsKey('include_metadata') &&
                                                config['include_metadata'] == 'true') {

                                              if (profile.containsKey('metadata')) {
                                                processedUser['metadata'] = profile['metadata'];
                                              }

                                              if (settings.containsKey('preferences')) {
                                                processedUser['preferences'] = settings['preferences'];
                                              }
                                            }

                                            if (!finalResult.containsKey('users')) {
                                              finalResult['users'] = [];
                                            }

                                            finalResult['users'].add(processedUser);
                                            successCount++;

                                            if (enableLogging) {
                                              print('Successfully processed user: $name');
                                            }
                                          } else {
                                            errors.add('Invalid role for user $userId: $role');
                                            errorCount++;
                                          }
                                        } else {
                                          if (!isActive) {
                                            warnings.add('User $userId is inactive');
                                          }
                                          if (!hasPermissions) {
                                            errors.add('User $userId has no permissions');
                                            errorCount++;
                                          }
                                        }
                                      } else {
                                        errors.add('User $userId missing settings');
                                        errorCount++;
                                      }
                                    } else {
                                      errors.add('Invalid email format for user $userId');
                                      errorCount++;
                                    }
                                  } else {
                                    errors.add('User $userId missing email');
                                    errorCount++;
                                  }
                                } else {
                                  errors.add('Invalid name for user $userId');
                                  errorCount++;
                                }
                              } else {
                                errors.add('User $userId missing name');
                                errorCount++;
                              }
                            } else {
                              errors.add('User $userId has empty profile');
                              errorCount++;
                            }
                          } else {
                            errors.add('User $userId missing profile');
                            errorCount++;
                          }
                        } else {
                          errors.add('Invalid user ID: $userId');
                          errorCount++;
                        }
                      } catch (e) {
                        errors.add('Error parsing user ID: ${e.toString()}');
                        errorCount++;
                      }
                    } else {
                      errors.add('Item $i missing user ID');
                      errorCount++;
                    }
                  } else {
                    errors.add('Item $i missing or invalid user data');
                    errorCount++;
                  }
                } else if (type == 'system') {
                  // Additional complex logic for system type
                  warnings.add('System type processing not fully implemented');
                } else {
                  errors.add('Unknown type: $type for item $i');
                  errorCount++;
                }
              } else {
                errors.add('Item $i missing type field');
                errorCount++;
              }
            } catch (e) {
              errors.add('Error processing item $i: ${e.toString()}');
              errorCount++;
            }
          } else {
            errors.add('Item $i is null or empty');
            errorCount++;
          }
        }
      } else {
        errors.add('Input data is null or empty');
        errorCount++;
      }

      finalResult['summary'] = {
        'total_processed': inputData.length,
        'success_count': successCount,
        'error_count': errorCount,
        'warnings_count': warnings.length,
      };

      if (errors.isNotEmpty) {
        finalResult['errors'] = errors;
      }

      if (warnings.isNotEmpty) {
        finalResult['warnings'] = warnings;
      }

      if (enableLogging) {
        print('Processing completed: $successCount successful, $errorCount errors');
      }

    } catch (e) {
      finalResult['fatal_error'] = e.toString();
      if (enableLogging) {
        print('Fatal error during processing: ${e.toString()}');
      }
    }

    return finalResult;
  }
}