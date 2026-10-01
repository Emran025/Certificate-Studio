part of '../project_details_screen.dart';

class _ProjectAction extends StatelessWidget {
  const _ProjectAction({required this.data});
  final _ProjectActionData data;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SizedBox(
      width: constraints.maxWidth >= 600 ? 410 : constraints.maxWidth,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        shadowColor: Theme.of(context).shadowColor,
        child: InkWell(
          onTap: data.onPressed,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: context.themeSelection,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: Icon(data.icon, color: context.themePrimary, size: 26),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.text(data.title),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        context.l10n.text(data.description),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.themeMutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 15,
                  color: context.themeMutedText,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
