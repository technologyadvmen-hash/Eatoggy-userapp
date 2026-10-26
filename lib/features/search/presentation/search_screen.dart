import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/models.dart';
import '../data/repositories/search_repository.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SearchRepository _searchRepository = SearchRepositoryImpl();
  List<FoodItem> _results = [];
  bool _isSearching = false;
  Timer? _debounceTimer;

  void _triggerSearch(String val) async {
    _debounceTimer?.cancel();
    final query = val.trim();
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _results = [];
          _isSearching = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isSearching = true;
      });
    }

    final results = await _searchRepository.search(query);

    if (mounted) {
      setState(() {
        _results = results;
        _isSearching = false;
      });
    }
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    if (val.trim().isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _triggerSearch(val);
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          onSubmitted: _triggerSearch,
          textInputAction: TextInputAction.search,
          autofocus: true,
          style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.primaryText),
          decoration: InputDecoration(
            hintText: 'Search royal dishes, curries, thalis...',
            border: InputBorder.none,
            hintStyle: const TextStyle(color: AppColors.muted),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                  )
                else ...[
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.secondaryText, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _triggerSearch('');
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.search, color: AppColors.primary, size: 22),
                    tooltip: 'Search',
                    onPressed: () => _triggerSearch(_searchController.text),
                  ),
                ],
              ],
            ),
          ),
        ),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: _isSearching
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _searchController.text.isEmpty
              ? SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.search, size: 56, color: AppColors.primary.withValues(alpha: 0.1)),
                            const SizedBox(height: 12),
                            const Text(
                              'Discover Culinary Masterpieces',
                              style: TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: 18,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Type a dish, cuisine, or restaurant name',
                              style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'POPULAR SEARCHES',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 10,
                        children: [
                          'Chicken Biryani',
                          'Shahi Paneer',
                          'The Great Kitchen',
                          'Royal Thali',
                          'Paneer Butter Masala',
                          'Paratha',
                          'Starters',
                          'Desserts',
                        ].map((term) => ActionChip(
                          label: Text(term),
                          labelStyle: const TextStyle(color: AppColors.primaryText, fontSize: 12),
                          backgroundColor: AppColors.surface,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          avatar: const Icon(Icons.trending_up, color: AppColors.primary, size: 14),
                          onPressed: () {
                            _searchController.text = term;
                            _triggerSearch(term);
                          },
                        )).toList(),
                      ),
                    ],
                  ),
                )
              : _results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.no_meals_outlined, size: 60, color: AppColors.muted),
                          const SizedBox(height: 12),
                          Text(
                            'No gourmet items found for "${_searchController.text}"',
                            style: const TextStyle(color: AppColors.secondaryText),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppConstants.p16),
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 16),
                      itemBuilder: (context, index) {
                        final food = _results[index];
                        final isNetwork = food.imageUrl.startsWith('http');

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 56,
                              height: 56,
                              child: isNetwork
                                  ? Image.network(
                                      food.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Image.asset(food.fallbackImageAsset, fit: BoxFit.cover),
                                    )
                                  : Image.asset(
                                      food.imageUrl.isNotEmpty ? food.imageUrl : food.fallbackImageAsset,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Image.asset(food.fallbackImageAsset, fit: BoxFit.cover),
                                    ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: food.isVeg ? Colors.green : Colors.red,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  food.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryText,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                food.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '₹${food.price.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (food.restaurantName != null && food.restaurantName!.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '• ${food.restaurantName}',
                                      style: const TextStyle(color: AppColors.muted, fontSize: 11),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                            ),
                            child: const Text(
                              'ADD',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          onTap: () => context.push('/food-detail', extra: food),
                        );
                      },
                    ),
    );
  }
}
