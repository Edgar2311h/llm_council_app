import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'presentation/bloc/settings/settings_bloc.dart';
import 'presentation/bloc/settings/settings_event.dart';
import 'presentation/bloc/settings/settings_state.dart';
import 'presentation/bloc/conversation/conversation_bloc.dart';
import 'presentation/bloc/council/council_bloc.dart';
import 'presentation/theme/executive_theme.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'presentation/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  runApp(const LLMCouncilApp());
}

class LLMCouncilApp extends StatelessWidget {
  const LLMCouncilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsBloc>(
          create: (_) => SettingsBloc()..add(LoadSettings()),
        ),
        BlocProvider<ConversationBloc>(
          create: (_) => ConversationBloc(),
        ),
      ],
      child: Builder(
        builder: (context) {
          return BlocProvider<CouncilBloc>(
            create: (context) => CouncilBloc(
              conversationBloc: context.read<ConversationBloc>(),
            ),
            child: MaterialApp(
              title: 'LLM Council',
              debugShowCheckedModeBanner: false,
              theme: ExecutiveTheme.darkTheme,
              home: BlocBuilder<SettingsBloc, SettingsState>(
                builder: (context, state) {
                  if (state is SettingsLoading || state is SettingsInitial) {
                    return const Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (state is SettingsLoaded) {
                    if (!state.isOnboardingComplete || !state.hasApiKey) {
                      return const OnboardingScreen();
                    }
                    return const HomeScreen();
                  }

                  // Error state - show onboarding as fallback
                  return const OnboardingScreen();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
