import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Providers/AuthProvider.dart';
import '../Resources/api_endpoints.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
    required AuthProvider authProvider,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user == null) {
        throw Exception("Login failed: User is null");
      }

      final DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        // Heal: Create missing user document
        final userData = {
          'email': user.email,
          'name': user.email?.split('@')[0] ?? 'User',
          'role': 'MARKETING', // Default role
          'createdAt': FieldValue.serverTimestamp(),
        };
        await _firestore.collection('users').doc(user.uid).set(userData);

        // Use the newly created data
        final normalizedUser = {
          'id': user.uid,
          'email': user.email,
          'role': userData['role'],
          'name': userData['name'],
        };

        authProvider.saveLoginData(
          token: await user.getIdToken() ?? "",
          user: normalizedUser,
        );
        return normalizedUser;
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      // Normalize data for AuthProvider
      final normalizedUser = {
        'id': user.uid,
        'email': user.email,
        'role': userData['role'] ??
            'MARKETING', // Default to restricted role if missing
        'name': userData['name'] ?? user.email?.split('@')[0] ?? 'User',
      };

      authProvider.saveLoginData(
        token: await user.getIdToken() ?? "", // Use Firebase ID token
        user: normalizedUser,
      );

      return normalizedUser;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        // Fallback to Legacy API
        try {
          return await _signInWithLegacyApi(
              email: email, password: password, authProvider: authProvider);
        } catch (legacyError) {
          throw Exception(
              e.message); // Throw original Firebase error if legacy fails
        }
      }
      throw Exception(e.message);
    } catch (e) {
      // rethrow;
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> _signInWithLegacyApi({
    required String email,
    required String password,
    required AuthProvider authProvider,
  }) async {
    print("Attempting Legacy Login...");
    final url = Uri.parse(ApiEndpoints.login);
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      // Check structure, assuming { user: { ... }, token: ... } or similar
      // Adjust based on actual API response structure.
      // Often it's data['user'] or just data.

      final userData = data['user'] ?? data;

      if (userData == null) throw Exception("Legacy login invalid response");

      final String name = userData['name'] ?? email.split('@')[0];
      final String role = userData['role'] ?? 'MARKETING';
      final String id = userData['_id'] ?? userData['id']; // MongoDB _id?

      print("Legacy Login Successful. Migrating user to Firebase...");

      // Create Firebase User
      try {
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final user = userCredential.user!;

        // Create Firestore Doc
        final firestoreData = {
          'email': email,
          'name': name,
          'role': role,
          'legacyId': id,
          'createdAt': FieldValue.serverTimestamp(),
        };

        await _firestore.collection('users').doc(user.uid).set(firestoreData);

        final normalizedUser = {
          'id': user.uid,
          'email': email,
          'role': role,
          'name': name,
        };

        authProvider.saveLoginData(
          token: await user.getIdToken() ?? "",
          user: normalizedUser,
        );

        return normalizedUser;
      } catch (migrationError) {
        print("Migration failed: $migrationError");
        throw Exception(
            "Login successful but migration failed. Please contact support.");
      }
    } else {
      throw Exception("Legacy login failed");
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    String? phone,
    required AuthProvider authProvider,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user == null) throw Exception("Signup failed");

      // Create user document in Firestore
      final userData = {
        'email': email,
        'name': name,
        'phone': phone,
        'role': 'MARKETING', // Default role on signup
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(user.uid).set(userData);

      final normalizedUser = {
        'id': user.uid,
        'email': user.email,
        'role': userData['role'],
        'name': userData['name'],
      };

      authProvider.saveLoginData(
          token: await user.getIdToken() ?? "", user: normalizedUser);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Create a school admin account
  Future<String> createSchoolAdmin({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String schoolId,
    Map<String, String>? apiKeys,
  }) async {
    try {
      // 1. Create User in Firebase Auth
      // Note: This signs in the NEW user automatically if using client SDK,
      // creating a secondary app instance or using Admin SDK is better backend practice.
      // But for client-side app mimicking admin tools:
      final secondaryApp = await _initializeSecondaryApp();

      final UserCredential userCredential =
          await FirebaseAuth.instanceFor(app: secondaryApp)
              .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user == null) throw Exception("Failed to create user");

      final String uid = user.uid;

      // 2. Create User Doc in Firestore
      final userData = {
        'email': email,
        'name': name,
        'phone': phone,
        'role': 'ADMIN', // specific role for school admins
        'schoolId': schoolId, // 4-digit ID
        'createdAt': FieldValue.serverTimestamp(),
        'apiKeys': apiKeys ?? {},
      };

      await _firestore.collection('users').doc(uid).set(userData);

      return uid;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Workaround to create user without logging out current user
  Future<FirebaseApp> _initializeSecondaryApp() async {
    const secondaryAppName = 'SecondaryApp';

    // Check if already exists
    try {
      final app = Firebase.app(secondaryAppName);
      return app;
    } catch (e) {
      // If not exists, initialize it
      final mainApp = Firebase.app();
      return await Firebase.initializeApp(
        name: secondaryAppName,
        options: mainApp.options,
      );
    }
  }

  Future<void> updateApiKeys(String uid, Map<String, dynamic> keys) async {
    await _firestore.collection('users').doc(uid).set(
      {
        'apiKeys': keys,
      },
      SetOptions(merge: true),
    );
  }

  Future<Map<String, dynamic>> getApiKeys(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data() as Map<String, dynamic>;
      return data['apiKeys'] ?? {};
    }
    return {};
  }
}
