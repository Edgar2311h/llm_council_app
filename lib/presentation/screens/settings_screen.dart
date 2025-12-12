import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../core/extensions.dart';
import '../../data/api/openrouter_client.dart';
import '../../data/storage/secure_storage_service.dart';
import '../bloc/settings/settings_bloc.dart';
import '../bloc/settings/settings_event.dart';
import '../bloc/settings/settings_state.dart';
import '../theme/executive_theme.dart';

/// Settings screen for API key and model configuration.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _isApiKeyObscured = true;
  bool _isEditingApiKey = false;

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _launchOpenRouterKeys() async {
    final uri = Uri.parse('https://openrouter.ai/settings/keys');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          if (state is SettingsLoaded) {
            return _buildSettings(state);
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildSettings(SettingsLoaded state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // API Key section
        _buildSectionHeader('OpenRouter API'),
        _buildApiKeyCard(state),

        const SizedBox(height: 24),

        // Council Models section
        _buildSectionHeader('Council Configuration'),
        _buildCouncilMembersCard(state),

        const SizedBox(height: 12),

        _buildChairmanCard(state),

        const SizedBox(height: 12),

        // Browse Models button
        if (state.hasApiKey)
          Card(
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ExecutiveTheme.primaryAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.explore,
                  color: ExecutiveTheme.goldAccent,
                  size: 20,
                ),
              ),
              title: const Text('Browse Available Models'),
              subtitle:
                  const Text('Select models from your OpenRouter account'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showModelBrowser(state),
            ),
          ),

        const SizedBox(height: 24),

        // Presets
        _buildSectionHeader('Quick Presets'),
        ...CouncilDefaults.presets.entries.map(
          (entry) => _buildPresetCard(entry.key, entry.value, state),
        ),

        const SizedBox(height: 24),

        // Data management
        _buildSectionHeader('Data Management'),
        _buildClearDataCard(),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildApiKeyCard(SettingsLoaded state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: state.hasApiKey
                        ? ExecutiveTheme.successColor.withValues(alpha: 0.2)
                        : ExecutiveTheme.errorColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    state.hasApiKey ? Icons.key : Icons.key_off,
                    color: state.hasApiKey
                        ? ExecutiveTheme.successColor
                        : ExecutiveTheme.errorColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'API Key',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        state.hasApiKey ? 'Configured' : 'Not configured',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: state.hasApiKey
                                  ? ExecutiveTheme.successColor
                                  : ExecutiveTheme.errorColor,
                            ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      setState(() => _isEditingApiKey = !_isEditingApiKey),
                  child: Text(_isEditingApiKey ? 'Cancel' : 'Update'),
                ),
              ],
            ),
            if (_isEditingApiKey) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _apiKeyController,
                obscureText: _isApiKeyObscured,
                decoration: InputDecoration(
                  hintText: 'sk-or-v1-...',
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(_isApiKeyObscured
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () => setState(
                            () => _isApiKeyObscured = !_isApiKeyObscured),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check),
                        color: ExecutiveTheme.successColor,
                        onPressed: () {
                          if (_apiKeyController.text.isNotEmpty) {
                            context.read<SettingsBloc>().add(
                                  VerifyApiKey(_apiKeyController.text.trim()),
                                );
                            setState(() => _isEditingApiKey = false);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
            // Get API Key button
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _launchOpenRouterKeys,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ExecutiveTheme.goldAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ExecutiveTheme.goldAccent.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.open_in_new,
                      size: 18,
                      color: ExecutiveTheme.goldAccent,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Get API key from OpenRouter',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: ExecutiveTheme.goldAccent,
                            ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: ExecutiveTheme.goldAccent,
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

  Widget _buildCouncilMembersCard(SettingsLoaded state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Council Members',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'These models will discuss your questions',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${state.settings.councilModels.length} models',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: ExecutiveTheme.goldAccent,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Swipe left to remove',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ExecutiveTheme.textDisabled,
                    fontSize: 11,
                  ),
            ),
            const SizedBox(height: 12),
            ...state.settings.councilModels.map(
              (model) => _buildModelChip(
                model,
                onDelete: () {
                  final updatedModels = state.settings.councilModels
                      .where((m) => m != model)
                      .toList();
                  if (updatedModels.isNotEmpty) {
                    context
                        .read<SettingsBloc>()
                        .add(UpdateCouncilModels(updatedModels));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cannot remove last council model'),
                        backgroundColor: ExecutiveTheme.errorColor,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChairmanCard(SettingsLoaded state) {
    return Card(
      child: InkWell(
        onTap: () => _showChairmanSelector(state),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: ExecutiveTheme.goldGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.gavel,
                      color: ExecutiveTheme.primaryBackground,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chairman Model',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'Tap to change • Synthesizes the final answer',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: ExecutiveTheme.textDisabled,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: ExecutiveTheme.textDisabled,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: ExecutiveTheme.goldAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ExecutiveTheme.goldAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.gavel,
                      size: 14,
                      color: ExecutiveTheme.goldAccent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      state.settings.chairmanModel.modelDisplayName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: ExecutiveTheme.goldAccent,
                          ),
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

  void _showChairmanSelector(SettingsLoaded state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ExecutiveTheme.cardBackground,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: ExecutiveTheme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.gavel, color: ExecutiveTheme.goldAccent),
                  const SizedBox(width: 12),
                  const Text(
                    'Select Chairman Model',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Choose from your council members or use a custom model',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ExecutiveTheme.textDisabled,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  // Current council members
                  ...state.settings.councilModels.map((model) {
                    final isSelected = model == state.settings.chairmanModel;
                    return ListTile(
                      leading: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? ExecutiveTheme.goldAccent.withValues(alpha: 0.2)
                              : ExecutiveTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isSelected ? Icons.gavel : Icons.smart_toy_outlined,
                          size: 16,
                          color: isSelected
                              ? ExecutiveTheme.goldAccent
                              : ExecutiveTheme.textSecondary,
                        ),
                      ),
                      title: Text(model.modelDisplayName),
                      subtitle: Text(
                        model.modelProvider,
                        style: TextStyle(color: ExecutiveTheme.textDisabled),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: ExecutiveTheme.goldAccent,
                            )
                          : null,
                      onTap: () {
                        context
                            .read<SettingsBloc>()
                            .add(UpdateChairmanModel(model));
                        Navigator.pop(context);
                      },
                    );
                  }),
                  // Divider and option to use Browse Models
                  const Divider(),
                  ListTile(
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color:
                            ExecutiveTheme.primaryAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.explore,
                        size: 16,
                        color: ExecutiveTheme.primaryAccent,
                      ),
                    ),
                    title: const Text('Browse More Models'),
                    subtitle: const Text('Select from all available models'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(context);
                      _showModelBrowser(state);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildClearDataCard() {
    return Card(
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: ExecutiveTheme.errorColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.delete_outline,
            color: ExecutiveTheme.errorColor,
            size: 20,
          ),
        ),
        title: const Text('Clear All Data'),
        subtitle: const Text('Delete all conversations and reset settings'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showClearDataDialog(),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: ExecutiveTheme.textSecondary,
            ),
      ),
    );
  }

  Widget _buildModelChip(String model, {VoidCallback? onDelete}) {
    final isFree = model.contains(':free');
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ExecutiveTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isFree
                  ? ExecutiveTheme.successColor
                  : ExecutiveTheme.goldAccent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model.modelDisplayName,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  model.modelProvider,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ExecutiveTheme.textDisabled,
                      ),
                ),
              ],
            ),
          ),
          if (isFree)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: ExecutiveTheme.successColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'FREE',
                style: TextStyle(
                  color: ExecutiveTheme.successColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );

    if (onDelete != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Dismissible(
          key: Key(model),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => onDelete(),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: ExecutiveTheme.errorColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.delete_outline,
              color: ExecutiveTheme.errorColor,
            ),
          ),
          child: content,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: content,
    );
  }

  Widget _buildPresetCard(
      String name, List<String> models, SettingsLoaded state) {
    final isActive = state.settings.councilModels.length == models.length &&
        state.settings.councilModels.every((m) => models.contains(m));
    final isFree = name.toLowerCase().contains('free');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          context.read<SettingsBloc>().add(UpdateCouncilModels(models));
          // If it's the free preset, also update chairman to free model
          if (isFree) {
            context.read<SettingsBloc>().add(
                  const UpdateChairmanModel(CouncilDefaults.freeChairmanModel),
                );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (isFree) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: ExecutiveTheme.successColor
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'FREE',
                              style: TextStyle(
                                color: ExecutiveTheme.successColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${models.length} models',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (isActive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ExecutiveTheme.successColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(
                      color: ExecutiveTheme.successColor,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showModelBrowser(SettingsLoaded state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ExecutiveTheme.cardBackground,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => ModelBrowserSheet(
          scrollController: scrollController,
          currentModels: state.settings.councilModels,
          currentChairman: state.settings.chairmanModel,
          onModelsSelected: (models, chairman) {
            context.read<SettingsBloc>().add(UpdateCouncilModels(models));
            if (chairman != null) {
              context.read<SettingsBloc>().add(UpdateChairmanModel(chairman));
            }
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all conversations and reset your settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<SettingsBloc>().add(ClearAllData());
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data cleared')),
              );
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: ExecutiveTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for browsing and selecting models from OpenRouter
class ModelBrowserSheet extends StatefulWidget {
  final ScrollController scrollController;
  final List<String> currentModels;
  final String currentChairman;
  final void Function(List<String> models, String? chairman) onModelsSelected;

  const ModelBrowserSheet({
    super.key,
    required this.scrollController,
    required this.currentModels,
    required this.currentChairman,
    required this.onModelsSelected,
  });

  @override
  State<ModelBrowserSheet> createState() => _ModelBrowserSheetState();
}

class _ModelBrowserSheetState extends State<ModelBrowserSheet> {
  List<Map<String, dynamic>>? _availableModels;
  List<Map<String, dynamic>>? _filteredModels;
  bool _isLoading = true;
  String? _error;
  final Set<String> _selectedModels = {};
  String? _selectedChairman;
  String _searchQuery = '';
  bool _showFreeOnly = false;

  @override
  void initState() {
    super.initState();
    _selectedModels.addAll(widget.currentModels);
    _selectedChairman = widget.currentChairman;
    _loadModels();
  }

  Future<void> _loadModels() async {
    try {
      final apiKey = await SecureStorageService.instance.getApiKey();
      if (apiKey == null) {
        setState(() {
          _error = 'No API key configured';
          _isLoading = false;
        });
        return;
      }

      final client = OpenRouterClient(apiKey: apiKey);
      final models = await client.getAvailableModels();

      if (models == null) {
        setState(() {
          _error = 'Failed to fetch models';
          _isLoading = false;
        });
        return;
      }

      // Sort models by name
      models.sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));

      setState(() {
        _availableModels = models;
        _filteredModels = models;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterModels() {
    if (_availableModels == null) return;

    setState(() {
      _filteredModels = _availableModels!.where((model) {
        final id = model['id'] as String;
        final name = model['name'] as String? ?? id;

        // Search filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          if (!id.toLowerCase().contains(query) &&
              !name.toLowerCase().contains(query)) {
            return false;
          }
        }

        // Free filter
        if (_showFreeOnly) {
          final pricing = model['pricing'] as Map<String, dynamic>?;
          if (pricing == null) return false;
          final prompt =
              double.tryParse(pricing['prompt']?.toString() ?? '1') ?? 1;
          final completion =
              double.tryParse(pricing['completion']?.toString() ?? '1') ?? 1;
          if (prompt > 0 || completion > 0) return false;
        }

        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Handle bar
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: ExecutiveTheme.dividerColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Select Models',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: _selectedModels.isNotEmpty
                    ? () => widget.onModelsSelected(
                          _selectedModels.toList(),
                          _selectedChairman,
                        )
                    : null,
                child: Text('Done (${_selectedModels.length})'),
              ),
            ],
          ),
        ),

        // Search and filter
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search models...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: ExecutiveTheme.surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  _searchQuery = value;
                  _filterModels();
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilterChip(
                    label: const Text('Free Only'),
                    selected: _showFreeOnly,
                    onSelected: (value) {
                      _showFreeOnly = value;
                      _filterModels();
                    },
                    selectedColor:
                        ExecutiveTheme.successColor.withValues(alpha: 0.2),
                    checkmarkColor: ExecutiveTheme.successColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_filteredModels?.length ?? 0} models',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Model list
        Expanded(
          child: _buildModelList(),
        ),
      ],
    );
  }

  Widget _buildModelList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: ExecutiveTheme.errorColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadModels,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredModels == null || _filteredModels!.isEmpty) {
      return const Center(child: Text('No models found'));
    }

    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredModels!.length,
      itemBuilder: (context, index) {
        final model = _filteredModels![index];
        return _buildModelItem(model);
      },
    );
  }

  Widget _buildModelItem(Map<String, dynamic> model) {
    final id = model['id'] as String;
    final name = model['name'] as String? ?? id;
    final pricing = model['pricing'] as Map<String, dynamic>?;
    final contextLength = model['context_length'] as int?;

    final promptPrice =
        double.tryParse(pricing?['prompt']?.toString() ?? '0') ?? 0;
    final isFree = promptPrice == 0;

    final isSelected = _selectedModels.contains(id);
    final isChairman = _selectedChairman == id;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedModels.remove(id);
              if (isChairman) _selectedChairman = null;
            } else {
              _selectedModels.add(id);
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Selection checkbox
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected
                      ? ExecutiveTheme.goldAccent
                      : ExecutiveTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? ExecutiveTheme.goldAccent
                        : ExecutiveTheme.dividerColor,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: ExecutiveTheme.primaryBackground,
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Model info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: Theme.of(context).textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isFree) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: ExecutiveTheme.successColor
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'FREE',
                              style: TextStyle(
                                color: ExecutiveTheme.successColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      id,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ExecutiveTheme.textDisabled,
                          ),
                    ),
                    if (contextLength != null)
                      Text(
                        'Context: ${(contextLength / 1000).toStringAsFixed(0)}k',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: ExecutiveTheme.textDisabled,
                            ),
                      ),
                  ],
                ),
              ),

              // Chairman toggle
              if (isSelected)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedChairman = isChairman ? null : id;
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isChairman
                          ? ExecutiveTheme.goldAccent.withValues(alpha: 0.2)
                          : ExecutiveTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isChairman
                            ? ExecutiveTheme.goldAccent
                            : ExecutiveTheme.dividerColor,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.gavel,
                          size: 14,
                          color: isChairman
                              ? ExecutiveTheme.goldAccent
                              : ExecutiveTheme.textDisabled,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Chair',
                          style: TextStyle(
                            fontSize: 11,
                            color: isChairman
                                ? ExecutiveTheme.goldAccent
                                : ExecutiveTheme.textDisabled,
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
