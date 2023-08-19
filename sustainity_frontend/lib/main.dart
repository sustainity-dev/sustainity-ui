import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:url_launcher/url_launcher.dart' as url_launcher;

import 'package:sustainity_api/sustainity_api.dart' as api;

import 'package:sustainity_frontend/configuration.dart';

const double defaultPadding = 10.0;
const double tileWidth = 180;
const double tileHeight = 240;
const double imageSize = 220;
const double medallionWidth = 240;
const double medallionHeight = 180;
const double badgeSize = 32;

void main() async {
  final config = Config.load();
  final fetcher = api.Fetcher(
    scheme: config.backend_scheme,
    host: config.backend_host,
    port: config.backend_port,
  );
  runApp(SustainityFrontend(fetcher: fetcher));
}

enum PreviewVariant { organisation, product }

class ScoreData {
  final api.ScorerName scorer;
  final int score;

  ScoreData({required this.scorer, required this.score});

  Color get color {
    var value = 0.0;
    switch (scorer) {
      case api.ScorerName.fti:
        value = score / 100.0;
    }
    return Color.fromRGBO(
        ((255 - 100 * value)).toInt(), (155 + 100 * value).toInt(), 155, 0x01);
  }
}

class PreviewData {
  final PreviewVariant variant;
  final String itemId;

  PreviewData({required this.variant, required this.itemId});
}

class Space extends StatelessWidget {
  const Space({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 10,
      height: 10,
    );
  }
}

class Title extends StatelessWidget {
  final String text;

  const Title({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context)
        .textTheme
        .headlineMedium
        ?.copyWith(color: Colors.black);
    return Padding(
      padding: const EdgeInsets.all(defaultPadding),
      child: Text(text, style: style),
    );
  }
}

class Section extends StatelessWidget {
  final String text;

  const Section({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.headlineSmall;
    return Padding(
      padding: const EdgeInsets.all(defaultPadding),
      child: Text(text, style: style),
    );
  }
}

class Description extends StatelessWidget {
  final String text;
  final api.Source? source;

  const Description({
    super.key,
    required this.text,
    this.source,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Colors.black,
        );
    final sourceStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.grey,
        );

    Widget? sourceWidget;
    switch (source) {
      case api.Source.wikidata:
        sourceWidget = Text("Source: Wikidata", style: sourceStyle);
        break;
      case api.Source.openFoodFacts:
        sourceWidget = Text("Source: Open Food Facts", style: sourceStyle);
        break;
      case api.Source.euEcolabel:
        sourceWidget = Text("Source: Eu Ecolabel", style: sourceStyle);
        break;
      case null:
        break;
    }

    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius:
              const BorderRadius.all(Radius.circular(defaultPadding))),
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(text, style: textStyle),
            if (sourceWidget != null) ...[
              const Space(),
              sourceWidget,
            ]
          ],
        ),
      ),
    );
  }
}

class Article extends StatelessWidget {
  final String markdown;

  const Article({
    super.key,
    required this.markdown,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.all(Radius.circular(defaultPadding)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: MarkdownBody(
          data: markdown,
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            blockquoteDecoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                left: BorderSide(
                  width: 3,
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
          ),
          onTapLink: (text, url, title) async {
            if (url != null) {
              await url_launcher.launchUrl(Uri.parse(url));
            }
          },
        ),
      ),
    );
  }
}

extension BCorpMedallionExtension on api.BCorpMedallion {
  String get icon {
    return "bcorp";
  }
}

extension EuEcolabelMedallionExtension on api.EuEcolabelMedallion {
  String get icon {
    return "eu_ecolabel";
  }
}

extension TcoMedallionExtension on api.TcoMedallion {
  String get icon {
    return "tco";
  }
}

const libraryTopicIconNames = [
  "main",
  "main",
  "main",
  "main",
  "main",
  "bcorp",
  "eu_ecolabel",
  "tco",
  "fti",
  "main",
];

extension LibraryTopicGuiExtension on api.LibraryTopic {
  String get icon {
    return libraryTopicIconNames[index];
  }
}

class FashionTransparencyIndexWidget extends StatelessWidget {
  final api.Presentation presentation;
  final Navigation navigation;

  FashionTransparencyIndexWidget({
    super.key,
    required this.presentation,
    required this.navigation,
  }) {
    presentation.data.sort((a, b) => b.score.compareTo(a.score));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        children: [
          for (final entry in presentation.data)
            ListTile(
              onTap: () => navigation.goToOrganisation(entry.id),
              mouseCursor: SystemMouseCursors.click,
              leading: Container(
                decoration: BoxDecoration(
                  color: ScoreData(
                    scorer: api.ScorerName.fti,
                    score: entry.score,
                  ).color,
                  borderRadius:
                      const BorderRadius.all(Radius.circular(defaultPadding)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(defaultPadding),
                  child: Text("${entry.score}%"),
                ),
              ),
              title: Text(entry.name),
            ),
        ],
      ),
    );
  }
}

class InfoWidget extends StatelessWidget {
  final api.LibraryInfoFull info;
  final Navigation navigation;

  const InfoWidget({
    super.key,
    required this.info,
    required this.navigation,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        children: [
          Title(text: info.title),
          const Space(),
          Expanded(
            child: ListView(
              scrollDirection: Axis.vertical,
              children: [
                Article(markdown: info.article),
                if (info.presentation != null) ...[
                  const Space(),
                  if (info.id == api.LibraryTopic.fti.name) ...[
                    FashionTransparencyIndexWidget(
                      presentation: info.presentation!,
                      navigation: navigation,
                    )
                  ]
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SourcedImage extends StatelessWidget {
  static const url1 = "https://commons.wikimedia.org/wiki/Special:FilePath";

  final api.Image image;

  const SourcedImage(this.image, {super.key});

  @override
  Widget build(BuildContext context) {
    String link;
    String url;
    String source;
    switch (image.source) {
      case api.Source.wikidata:
        link = "$url1/${image.image}";
        url = "$link?width=200";
        source = "Wikidata";
        break;
      case api.Source.openFoodFacts:
        link = image.image;
        url = image.image;
        source = "Open Food Facts";
        break;
      case api.Source.euEcolabel:
        link = image.image;
        url = image.image;
        source = "Eu Ecolabel";
        break;
    }

    return Column(
      children: [
        Image.network(
          url,
          width: imageSize,
          height: imageSize,
        ),
        Tooltip(
          message: link,
          child: Text("Source: $source"),
        ),
      ],
    );
  }
}

class LibraryContentsView extends StatelessWidget {
  static const double iconSize = 32;

  final api.LibraryContentsResponse contents;
  final Navigation navigation;

  const LibraryContentsView(
      {super.key, required this.contents, required this.navigation});

  @override
  Widget build(BuildContext context) {
    final aboutUs = contents.items.where((i) => i.id.startsWith("info:"));
    final aboutData = contents.items
        .where((i) => i.id.startsWith("cert:") || i.id.startsWith("data:"));

    return ListView(
      scrollDirection: Axis.vertical,
      children: [
        const Center(child: Section(text: "About us")),
        ...aboutUs.map((item) {
          return ListTile(
            leading: const Icon(Icons.question_answer_outlined),
            title: Text(item.title),
            subtitle: Text(item.summary),
            onTap: () => navigation.goToLibrary(
              api.LibraryTopicExtension.fromString(item.id),
            ),
          );
        }),
        const Center(
            child: Section(text: "About certifications and data sources")),
        ...aboutData.map((item) {
          final topic = api.LibraryTopicExtension.fromString(item.id);
          return ListTile(
            leading: Image(
              image: AssetImage('images/${topic.icon}.png'),
              height: iconSize,
              width: iconSize,
            ),
            title: Text(item.title),
            subtitle: Text(item.summary),
            onTap: () => navigation.goToLibrary(topic),
          );
        }),
      ],
    );
  }
}

class LibraryItemView extends StatefulWidget {
  final api.LibraryTopic topic;
  final api.Fetcher fetcher;
  final Navigation navigation;

  const LibraryItemView({
    super.key,
    required this.topic,
    required this.fetcher,
    required this.navigation,
  });

  @override
  State<LibraryItemView> createState() => _LibraryItemViewState();
}

class _LibraryItemViewState extends State<LibraryItemView>
    with AutomaticKeepAliveClientMixin {
  late Future<api.LibraryInfoFull> _futureInfo;

  @override
  void initState() {
    super.initState();
    _futureInfo = widget.fetcher.fetchLibraryInfo(widget.topic);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Center(
      child: FutureBuilder<api.LibraryInfoFull>(
        future: _futureInfo,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return InfoWidget(
              info: snapshot.data!,
              navigation: widget.navigation,
            );
          } else if (snapshot.hasError) {
            return Text('Error while fetching data: ${snapshot.error}');
          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}

class LibraryPage extends StatefulWidget {
  final api.Fetcher fetcher;
  final Navigation navigation;

  const LibraryPage({
    super.key,
    required this.fetcher,
    required this.navigation,
  });

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late Future<api.LibraryContentsResponse> _futureLibraryContents;

  @override
  void initState() {
    super.initState();
    _futureLibraryContents = widget.fetcher.fetchLibraryContents();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Center(
      child: FutureBuilder<api.LibraryContentsResponse>(
        future: _futureLibraryContents,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return LibraryContentsView(
              contents: snapshot.data!,
              navigation: widget.navigation,
            );
          } else if (snapshot.hasError) {
            return Text('Error while fetching data: ${snapshot.error}');
          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}

class SearchEntryWidget extends StatelessWidget {
  final api.SearchResult entry;
  final Navigation navigation;

  const SearchEntryWidget({
    super.key,
    required this.entry,
    required this.navigation,
  });

  @override
  Widget build(BuildContext context) {
    Widget icon;
    Function() onTap;
    switch (entry.variant) {
      case api.SearchResultVariant.organisation:
        icon = const Tooltip(
          message: "manufacturer / organisation / business / shop",
          child: Icon(Icons.business_outlined),
        );
        onTap = () => navigation.goToOrganisation(entry.id);
        break;
      case api.SearchResultVariant.product:
        icon = const Tooltip(
          message: "product / brand / item category",
          child: Icon(Icons.shopping_basket_outlined),
        );
        onTap = () => navigation.goToProduct(entry.id);
        break;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: ListTile(
        onTap: onTap,
        leading: icon,
        title: Text(entry.label),
      ),
    );
  }
}

class ProductTileWidget extends StatelessWidget {
  final api.ProductShort product;
  final Function(String) onSelected;
  final Function(api.BadgeName) onBadgeTap;
  final Function(api.ScorerName) onScorerTap;

  const ProductTileWidget({
    super.key,
    required this.product,
    required this.onSelected,
    required this.onBadgeTap,
    required this.onScorerTap,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        );
    final textStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Colors.black,
        );

    return Padding(
      padding: const EdgeInsets.all(defaultPadding),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            onSelected(product.productId);
          },
          child: Container(
            width: tileWidth,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius:
                  const BorderRadius.all(Radius.circular(defaultPadding)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: titleStyle),
                  const Space(),
                  Text(
                    product.description != null ? product.description! : "",
                    style: textStyle,
                  ),
                  const Space(),
                  RibbonRow(
                    badges: product.badges,
                    scores: product.scores,
                    onBadgeTap: onBadgeTap,
                    onScorerTap: onScorerTap,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Badge extends StatelessWidget {
  final api.BadgeName badge;
  final Function(api.BadgeName) onTap;

  const Badge({super.key, required this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          onTap(badge);
        },
        child: Image(
          image: AssetImage('images/${badge.toLibraryTopic().icon}.png'),
          height: badgeSize,
          width: badgeSize,
        ),
      ),
    );
  }
}

class Score extends StatelessWidget {
  final ScoreData score;
  final Function(api.ScorerName)? onTap;

  const Score({
    super.key,
    required this.score,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (onTap != null) {
            onTap!(score.scorer);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: score.color,
            borderRadius:
                const BorderRadius.all(Radius.circular(defaultPadding)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(defaultPadding),
            child: Row(
              children: [
                Image(
                  image: AssetImage(
                      'images/${score.scorer.toLibraryTopic().icon}.png'),
                  height: badgeSize,
                  width: badgeSize,
                ),
                const Space(),
                Text("${score.score}%"),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RibbonFlex extends StatelessWidget {
  final List<api.BadgeName>? badges;
  final Map<api.ScorerName, int>? scores;
  final Axis axis;
  final Function(api.BadgeName) onBadgeTap;
  final Function(api.ScorerName) onScorerTap;

  const RibbonFlex({
    super.key,
    required this.badges,
    required this.scores,
    required this.axis,
    required this.onBadgeTap,
    required this.onScorerTap,
  });

  @override
  Widget build(BuildContext context) {
    return Flex(
      direction: axis,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (badges != null) ...[
          for (final badge in badges!) Badge(badge: badge, onTap: onBadgeTap)
        ],
        if (scores != null) ...[
          for (final entry in scores!.entries)
            Score(
              score: ScoreData(scorer: entry.key, score: entry.value),
              onTap: onScorerTap,
            )
        ],
      ],
    );
  }
}

class RibbonColumn extends RibbonFlex {
  const RibbonColumn({
    super.key,
    List<api.BadgeName>? badges,
    Map<api.ScorerName, int>? scores,
    required Function(api.BadgeName) onBadgeTap,
    required Function(api.ScorerName) onScorerTap,
  }) : super(
          badges: badges,
          scores: scores,
          axis: Axis.vertical,
          onBadgeTap: onBadgeTap,
          onScorerTap: onScorerTap,
        );
}

class RibbonRow extends RibbonFlex {
  const RibbonRow({
    super.key,
    List<api.BadgeName>? badges,
    Map<api.ScorerName, int>? scores,
    required Function(api.BadgeName) onBadgeTap,
    required Function(api.ScorerName) onScorerTap,
  }) : super(
            badges: badges,
            scores: scores,
            axis: Axis.horizontal,
            onBadgeTap: onBadgeTap,
            onScorerTap: onScorerTap);
}

class MedallionFrame extends StatelessWidget {
  final Widget child;
  final Color color;

  const MedallionFrame({super.key, required this.child, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(defaultPadding),
      child: Container(
        height: medallionHeight,
        width: medallionWidth,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.all(Radius.circular(defaultPadding)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: child,
        ),
      ),
    );
  }
}

class BCorpMedallion extends StatelessWidget {
  final api.BCorpMedallion medallion;
  final Function(api.LibraryTopic) onTopic;

  const BCorpMedallion({
    super.key,
    required this.medallion,
    required this.onTopic,
  });

  @override
  Widget build(BuildContext context) {
    final mainStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Colors.black,
        );
    final commentStyle = Theme.of(context).textTheme.bodyMedium;

    return MedallionFrame(
      color: Colors.green.shade200,
      child: Column(
        children: [
          Text("Certified by:", style: commentStyle),
          const Spacer(),
          Center(
            child: Row(
              children: [
                const Spacer(),
                Image(
                  image: AssetImage('images/${medallion.icon}.png'),
                  height: badgeSize,
                  width: badgeSize,
                ),
                const Space(),
                Text(
                  "BCorporations",
                  style: mainStyle,
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
              ],
            ),
          ),
          const Spacer(),
          Row(children: [
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.bug_report_outlined),
              onPressed: () async {
                final url = Uri.parse(
                    'https://github.com/sustainity-dev/issues/issues/new');
                await url_launcher.launchUrl(url);
              },
            ),
            IconButton(
              icon: const Icon(Icons.info_outlined),
              onPressed: () => onTopic(api.LibraryTopic.bcorp),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_outward_outlined),
              onPressed: () async {
                final url = Uri.parse(
                    'https://www.bcorporation.net/en-us/find-a-b-corp/company/${medallion.id}/');
                await url_launcher.launchUrl(url);
              },
            ),
          ])
        ],
      ),
    );
  }
}

class EuEcolabelMedallion extends StatelessWidget {
  final api.EuEcolabelMedallion medallion;
  final Function(api.LibraryTopic) onTopic;

  const EuEcolabelMedallion({
    super.key,
    required this.medallion,
    required this.onTopic,
  });

  @override
  Widget build(BuildContext context) {
    final mainStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Colors.black,
        );
    final commentStyle = Theme.of(context).textTheme.bodyMedium;

    return MedallionFrame(
      color: Colors.green.shade200,
      child: Column(
        children: [
          Text("Certified by:", style: commentStyle),
          const Spacer(),
          Center(
            child: Row(
              children: [
                const Spacer(),
                Image(
                  image: AssetImage('images/${medallion.icon}.png'),
                  height: badgeSize,
                  width: badgeSize,
                ),
                const Space(),
                Text(
                  "EU Ecolabel",
                  style: mainStyle,
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
              ],
            ),
          ),
          const Spacer(),
          Row(children: [
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.bug_report_outlined),
              onPressed: () async {
                final url = Uri.parse(
                  'https://github.com/sustainity-dev/issues/issues/new',
                );
                await url_launcher.launchUrl(url);
              },
            ),
            IconButton(
              icon: const Icon(Icons.info_outlined),
              onPressed: () => onTopic(api.LibraryTopic.euEcolabel),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_outward_outlined),
              onPressed: () async {
                final url = Uri.parse(
                  'https://environment.ec.europa.eu/topics/circular-economy/eu-ecolabel-home_en',
                );
                await url_launcher.launchUrl(url);
              },
            ),
          ])
        ],
      ),
    );
  }
}

class FtiMedallion extends StatelessWidget {
  final api.FtiMedallion medallion;
  final Function(api.LibraryTopic) onTopic;

  const FtiMedallion({
    super.key,
    required this.medallion,
    required this.onTopic,
  });

  @override
  Widget build(BuildContext context) {
    final mainStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Colors.black,
        );
    final commentStyle = Theme.of(context).textTheme.bodyMedium;

    final score = ScoreData(
      scorer: api.ScorerName.fti,
      score: medallion.score,
    );

    return MedallionFrame(
      color: score.color,
      child: Column(children: [
        Text(
          "Fashion Transparency Index",
          style: mainStyle,
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        Row(
          children: [
            const Spacer(),
            Text("Score:", style: commentStyle),
            const Spacer(),
            Text("${medallion.score}%", style: mainStyle),
            const Spacer(),
          ],
        ),
        const Spacer(),
        Row(children: [
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: () async {
              final url = Uri.parse(
                  'https://github.com/sustainity-dev/issues/issues/new');
              await url_launcher.launchUrl(url);
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outlined),
            onPressed: () => onTopic(api.LibraryTopic.fti),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_outward_outlined),
            onPressed: () async {
              final url = Uri.parse(
                  'https://www.fashionrevolution.org/about/transparency/');
              await url_launcher.launchUrl(url);
            },
          ),
        ])
      ]),
    );
  }
}

class TcoMedallion extends StatelessWidget {
  final api.TcoMedallion medallion;
  final Function(api.LibraryTopic) onTopic;

  const TcoMedallion({
    super.key,
    required this.medallion,
    required this.onTopic,
  });

  @override
  Widget build(BuildContext context) {
    final mainStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Colors.black,
        );
    final commentStyle = Theme.of(context).textTheme.bodyMedium;

    return MedallionFrame(
      color: Colors.green.shade200,
      child: Column(
        children: [
          Text("Certified by:", style: commentStyle),
          const Spacer(),
          Center(
            child: Row(
              children: [
                const Spacer(),
                Image(
                  image: AssetImage('images/${medallion.icon}.png'),
                  height: badgeSize,
                  width: badgeSize,
                ),
                const Space(),
                Text(
                  "TCO",
                  style: mainStyle,
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
              ],
            ),
          ),
          const Spacer(),
          Row(children: [
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.bug_report_outlined),
              onPressed: () async {
                final url = Uri.parse(
                    'https://github.com/sustainity-dev/issues/issues/new');
                await url_launcher.launchUrl(url);
              },
            ),
            IconButton(
              icon: const Icon(Icons.info_outlined),
              onPressed: () => onTopic(api.LibraryTopic.tco),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_outward_outlined),
              onPressed: () async {
                final url = Uri.parse(
                    'https://tcocertified.com/product-finder/index?brand=${medallion.brandName}');
                await url_launcher.launchUrl(url);
              },
            ),
          ])
        ],
      ),
    );
  }
}

class MedallionSwitcher extends StatelessWidget {
  final api.Medallion medallion;
  final Function(api.LibraryTopic) onTopic;

  const MedallionSwitcher({
    super.key,
    required this.medallion,
    required this.onTopic,
  });

  @override
  Widget build(BuildContext context) {
    switch (medallion.runtimeType) {
      case api.BCorpMedallion:
        return BCorpMedallion(
          medallion: medallion as api.BCorpMedallion,
          onTopic: onTopic,
        );
      case api.EuEcolabelMedallion:
        return EuEcolabelMedallion(
          medallion: medallion as api.EuEcolabelMedallion,
          onTopic: onTopic,
        );
      case api.FtiMedallion:
        return FtiMedallion(
          medallion: medallion as api.FtiMedallion,
          onTopic: onTopic,
        );
      case api.SustainityMedallion:
        return SustainityMedallion(
          medallion: medallion as api.SustainityMedallion,
        );
      case api.TcoMedallion:
        return TcoMedallion(
          medallion: medallion as api.TcoMedallion,
          onTopic: onTopic,
        );
    }
    return const Space();
  }
}

class SustainityMedallion extends StatelessWidget {
  final api.SustainityMedallion medallion;

  const SustainityMedallion({super.key, required this.medallion});

  @override
  Widget build(BuildContext context) {
    final mainStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Colors.black,
        );
    final commentStyle = Theme.of(context).textTheme.bodyMedium;

    return MedallionFrame(
      color: Colors.yellow.shade200,
      child: Column(
        children: [
          Text(
            "Sustainity score",
            style: mainStyle,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          Text(
            "${(10 * medallion.score.total).toStringAsFixed(2)} / 10",
            style: mainStyle,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          Text(
            "This is still work in progress!",
            style: commentStyle,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          Row(
            children: [
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.bug_report_outlined),
                onPressed: () async {
                  final url = Uri.parse(
                      'https://github.com/sustainity-dev/issues/issues/new');
                  await url_launcher.launchUrl(url);
                },
              ),
              IconButton(
                icon: const Icon(Icons.more_outlined),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return SustainityScoreDetailsPopup(
                        score: medallion.score,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class GhgMedallion extends StatelessWidget {
  const GhgMedallion({super.key});

  @override
  Widget build(BuildContext context) {
    final mainStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Colors.black,
        );
    final commentStyle = Theme.of(context).textTheme.bodyMedium;

    return MedallionFrame(
      color: Colors.grey.shade400,
      child: Column(
        children: [
          Text(
            "CO2 emissions",
            style: mainStyle,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          Row(children: [
            const Spacer(),
            Text("During production:", style: commentStyle),
            const Spacer(),
            Text("?", style: mainStyle),
            const Spacer(),
          ]),
          const Spacer(),
          Row(children: [
            const Spacer(),
            Text("During exploitation:", style: commentStyle),
            const Spacer(),
            Text("?", style: mainStyle),
            const Spacer(),
          ]),
          const Spacer(),
          Text(
            "More data needed.\nWe are working on it!",
            style: commentStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class DisposalMedallion extends StatelessWidget {
  const DisposalMedallion({super.key});

  @override
  Widget build(BuildContext context) {
    final mainStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Colors.black,
        );
    final commentStyle = Theme.of(context).textTheme.bodyMedium;

    return MedallionFrame(
      color: Colors.grey.shade400,
      child: Column(
        children: [
          Text(
            "Disposal",
            style: mainStyle,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          Row(children: [
            const Spacer(),
            Text("Product:", style: commentStyle),
            const Spacer(),
            Text("?", style: mainStyle),
            const Spacer(),
          ]),
          const Spacer(),
          Row(children: [
            const Spacer(),
            Text("Packaging:", style: commentStyle),
            const Spacer(),
            Text("?", style: mainStyle),
            const Spacer(),
          ]),
          const Spacer(),
          Text(
            "More data needed.\nWe are working on it!",
            style: commentStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OrganisationMedallions extends StatelessWidget {
  final List<api.Medallion> medallions;
  final Function(api.LibraryTopic) onTopic;

  const OrganisationMedallions({
    super.key,
    required this.medallions,
    required this.onTopic,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      direction: Axis.horizontal,
      children: [
        for (final medallion in medallions)
          MedallionSwitcher(medallion: medallion, onTopic: onTopic),
      ],
    );
  }
}

class ProductMedallions extends StatelessWidget {
  final List<api.Medallion> medallions;
  final Function(api.LibraryTopic) onTopic;

  const ProductMedallions({
    super.key,
    required this.medallions,
    required this.onTopic,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      direction: Axis.horizontal,
      children: [
        for (final medallion in medallions)
          MedallionSwitcher(medallion: medallion, onTopic: onTopic),
        const GhgMedallion(),
        const DisposalMedallion(),
      ],
    );
  }
}

class OperationsMenu extends StatelessWidget {
  final PreviewVariant variant;
  final Navigation navigation;

  const OperationsMenu({
    super.key,
    required this.variant,
    required this.navigation,
  });

  @override
  Widget build(BuildContext context) {
    var tipText = "";
    switch (variant) {
      case PreviewVariant.organisation:
        tipText = "Are you associated with this organisation? Read these tips!";
        break;
      case PreviewVariant.product:
        tipText =
            "Are you associated with producer of this item? Read these tips!";
        break;
    }

    return Padding(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: () {
              navigation.goToLibrary(api.LibraryTopic.forProducers);
            },
            icon: const Icon(Icons.tips_and_updates_outlined),
            label: Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Text(tipText),
            ),
          ),
          const Space(),
          ElevatedButton.icon(
            onPressed: () async {
              final url = Uri.parse(
                  'https://github.com/sustainity-dev/issues/issues/new');
              await url_launcher.launchUrl(url);
            },
            icon: const Icon(Icons.bug_report_outlined),
            label: const Padding(
              padding: EdgeInsets.all(defaultPadding),
              child: Text("Found problem with data? Report it to us!"),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductListWidget extends StatelessWidget {
  final List<api.ProductShort> products;
  final String emptyText;
  final Navigation navigation;

  const ProductListWidget({
    super.key,
    required this.products,
    required this.emptyText,
    required this.navigation,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isNotEmpty) {
      return SizedBox(
        height: tileHeight,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (final product in products)
              ProductTileWidget(
                product: product,
                onSelected: navigation.goToProduct,
                onBadgeTap: navigation.onBadgeTap,
                onScorerTap: navigation.onScorerTap,
              ),
          ],
        ),
      );
    } else {
      return Center(child: Text(emptyText));
    }
  }
}

class CategoryAlternativesWidget extends StatelessWidget {
  final api.CategoryAlternatives ca;
  final Navigation navigation;

  const CategoryAlternativesWidget({
    super.key,
    required this.ca,
    required this.navigation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Section(text: 'Alternatives (category: "${ca.category}")'),
        ProductListWidget(
          products: ca.alternatives,
          emptyText:
              "No alternatives?... That might be some problem in our data...",
          navigation: navigation,
        ),
      ],
    );
  }
}

class SustainityScoreBranchesWidget extends StatelessWidget {
  static const double textPadding = 10.0;
  static const double tablePadding = 8.0;

  final List<api.SustainityScoreBranch> branches;

  const SustainityScoreBranchesWidget({
    super.key,
    required this.branches,
  });

  @override
  Widget build(BuildContext context) {
    final symbolStyle = Theme.of(context).textTheme.headlineSmall;

    return Table(
      border: const TableBorder(
        horizontalInside: BorderSide(width: 1.0, color: Colors.black),
        verticalInside: BorderSide(width: 1.0, color: Colors.black),
      ),
      columnWidths: const <int, TableColumnWidth>{
        0: IntrinsicColumnWidth(),
        1: IntrinsicColumnWidth(),
        2: IntrinsicColumnWidth(),
        3: IntrinsicColumnWidth(),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        for (final branch in branches)
          TableRow(
            children: [
              Tooltip(
                message: branch.description,
                child: Padding(
                  padding: const EdgeInsets.all(textPadding),
                  child: Text(branch.symbol, style: symbolStyle),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(textPadding),
                child: Text("${branch.weight}"),
              ),
              Padding(
                padding: const EdgeInsets.all(textPadding),
                child: Text("${branch.score.toStringAsFixed(2)}"),
              ),
              branch.branches.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(tablePadding),
                      child: SustainityScoreBranchesWidget(
                        branches: branch.branches,
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(tablePadding),
                      child: Text(
                        (branch.score > 0.5) ? '✔' : '✖',
                        style: symbolStyle,
                      ),
                    ),
            ],
          ),
      ],
    );
  }
}

class SustainityScoreDetailsWidget extends StatelessWidget {
  final api.SustainityScore score;

  const SustainityScoreDetailsWidget({
    super.key,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final mainStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Colors.black,
        );

    return Flexible(
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SustainityScoreBranchesWidget(branches: score.tree),
                Text(
                  "Total: ${score.total.toStringAsFixed(3)}",
                  style: mainStyle,
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SustainityScoreDetailsPopup extends StatelessWidget {
  final api.SustainityScore score;

  const SustainityScoreDetailsPopup({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final headerStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Colors.black,
        );

    return Dialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(defaultPadding)),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius:
                const BorderRadius.all(Radius.circular(defaultPadding))),
        child: Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      "Sustainity score details",
                      style: headerStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              SustainityScoreDetailsWidget(score: score),
            ],
          ),
        ),
      ),
    );
  }
}

class OrganisationWidget extends StatelessWidget {
  final api.OrganisationShort organisation;
  final String source;
  final Function(api.BadgeName) onBadgeTap;
  final Function(api.ScorerName) onScorerTap;

  const OrganisationWidget({
    super.key,
    required this.organisation,
    required this.source,
    required this.onBadgeTap,
    required this.onScorerTap,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        );
    final textStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Colors.black,
        );
    final sourceStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.grey,
        );

    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius:
              const BorderRadius.all(Radius.circular(defaultPadding))),
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(organisation.name, style: titleStyle),
                  const Space(),
                  Text(
                      organisation.description != null
                          ? organisation.description!
                          : "",
                      style: textStyle),
                  const Space(),
                  Text("Source: $source", style: sourceStyle),
                ],
              ),
            ),
            RibbonColumn(
              badges: organisation.badges,
              scores: organisation.scores,
              onBadgeTap: onBadgeTap,
              onScorerTap: onScorerTap,
            ),
          ],
        ),
      ),
    );
  }
}

class ExampleSearchBox extends StatelessWidget {
  final String query;
  final String tip;
  final Function(String) onSubmitted;

  const ExampleSearchBox({
    super.key,
    required this.query,
    required this.tip,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final queryStyle = Theme.of(context).textTheme.headlineSmall;
    final tipStyle = Theme.of(context).textTheme.bodyLarge;

    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius:
              const BorderRadius.all(Radius.circular(defaultPadding))),
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SelectableText('"$query"', style: queryStyle),
                const Spacer(),
                FilledButton(
                  onPressed: () => onSubmitted(query),
                  child: const Text('Search'),
                ),
              ],
            ),
            const Space(),
            Text(tip, style: tipStyle),
          ],
        ),
      ),
    );
  }
}

class OrganisationView extends StatelessWidget {
  final api.OrganisationFull organisation;
  final String source;
  final Navigation navigation;

  const OrganisationView({
    super.key,
    required this.organisation,
    required this.source,
    required this.navigation,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        children: [
          Title(text: organisation.names[0].text),
          const Space(),
          Expanded(
            child: ListView(
              children: [
                const Section(text: 'Descriptions:'),
                if (organisation.descriptions.isNotEmpty) ...[
                  for (final description in organisation.descriptions)
                    Description(
                      text: description.text,
                      source: description.source,
                    )
                ] else ...[
                  const Center(child: Text("No description..."))
                ],
                OrganisationMedallions(
                  medallions: organisation.medallions,
                  onTopic: navigation.goToLibrary,
                ),
                const Section(text: 'Images'),
                if (organisation.images.isNotEmpty) ...[
                  SizedBox(
                    height: tileHeight,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final image in organisation.images)
                          SourcedImage(image)
                      ],
                    ),
                  )
                ] else ...[
                  const Center(child: Text("No images..."))
                ],
                const Section(text: 'Example products'),
                ProductListWidget(
                  products: organisation.products,
                  emptyText: "Seems like this organisation has no products...",
                  navigation: navigation,
                ),
                OperationsMenu(
                  variant: PreviewVariant.organisation,
                  navigation: navigation,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProductView extends StatelessWidget {
  final api.ProductFull product;
  final Navigation navigation;

  const ProductView({
    super.key,
    required this.product,
    required this.navigation,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        children: [
          Title(text: product.names.map((n) => n.text).join("\n")),
          const Space(),
          Expanded(
            child: ListView(
              children: [
                const Section(text: 'Descriptions:'),
                if (product.descriptions.isNotEmpty) ...[
                  for (final description in product.descriptions)
                    Description(
                      text: description.text,
                      source: description.source,
                    )
                ] else ...[
                  const Center(child: Text("No description..."))
                ],
                ProductMedallions(
                  medallions: product.medallions,
                  onTopic: navigation.goToLibrary,
                ),
                const Section(text: 'Producers:'),
                if (product.manufacturers != null) ...[
                  for (final manufacturer in product.manufacturers!)
                    OrganisationWidget(
                      organisation: manufacturer,
                      source: "wikidata",
                      onBadgeTap: navigation.onBadgeTap,
                      onScorerTap: navigation.onScorerTap,
                    )
                ],
                const Section(text: 'Images'),
                if (product.images.isNotEmpty) ...[
                  SizedBox(
                    height: tileHeight,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final image in product.images) SourcedImage(image)
                      ],
                    ),
                  )
                ] else ...[
                  const Center(child: Text("No images..."))
                ],
                for (final a in product.alternatives)
                  CategoryAlternativesWidget(ca: a, navigation: navigation),
                const Section(text: 'Barcodes'),
                product.gtins.isNotEmpty
                    ? Description(text: product.gtins.join(", "))
                    : const Center(child: Text("No barcodes...")),
                OperationsMenu(
                  variant: PreviewVariant.product,
                  navigation: navigation,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OrganisationPage extends StatefulWidget {
  final String organisationId;
  final Navigation navigation;
  final api.Fetcher fetcher;

  const OrganisationPage({
    super.key,
    required this.organisationId,
    required this.navigation,
    required this.fetcher,
  });

  @override
  State<OrganisationPage> createState() => _OrganisationPageState();
}

class _OrganisationPageState extends State<OrganisationPage>
    with AutomaticKeepAliveClientMixin {
  late Future<api.OrganisationFull> _futureOrganisation;

  @override
  void initState() {
    super.initState();
    _futureOrganisation =
        widget.fetcher.fetchOrganisation(widget.organisationId);
  }

  @override
  void didUpdateWidget(OrganisationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _futureOrganisation =
        widget.fetcher.fetchOrganisation(widget.organisationId);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Center(
      child: FutureBuilder<api.OrganisationFull>(
        future: _futureOrganisation,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return OrganisationView(
              organisation: snapshot.data!,
              source: "wikidata",
              navigation: widget.navigation,
            );
          } else if (snapshot.hasError) {
            return Text('Error while fetching data: ${snapshot.error}');
          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}

class ProductPage extends StatefulWidget {
  final String productId;
  final Navigation navigation;
  final api.Fetcher fetcher;

  const ProductPage({
    super.key,
    required this.productId,
    required this.navigation,
    required this.fetcher,
  });

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage>
    with AutomaticKeepAliveClientMixin {
  late Future<api.ProductFull> _futureProduct;

  @override
  void initState() {
    super.initState();
    _futureProduct = widget.fetcher.fetchProduct(widget.productId);
  }

  @override
  void didUpdateWidget(ProductPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _futureProduct = widget.fetcher.fetchProduct(widget.productId);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Center(
      child: FutureBuilder<api.ProductFull>(
        future: _futureProduct,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ProductView(
              product: snapshot.data!,
              navigation: widget.navigation,
            );
          } else if (snapshot.hasError) {
            return Text('Error while fetching data: ${snapshot.error}');
          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}

class TextSearchPage extends StatefulWidget {
  final api.Fetcher fetcher;
  final Navigation navigation;

  const TextSearchPage({
    super.key,
    required this.fetcher,
    required this.navigation,
  });

  @override
  State<TextSearchPage> createState() => _TextSearchPageState();
}

class _TextSearchPageState extends State<TextSearchPage>
    with AutomaticKeepAliveClientMixin {
  final _searchFieldController = TextEditingController();

  bool _searching = false;
  List<api.SearchResult> _entries = [];

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final largeStyle = Theme.of(context).textTheme.headlineSmall;

    return Padding(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        children: [
          Row(
            children: [
              Flexible(
                child: TextField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Text search',
                  ),
                  controller: _searchFieldController,
                  onSubmitted: _onSubmitted,
                ),
              ),
              const Space(),
              FilledButton(
                onPressed: () => _onSubmitted(_searchFieldController.text),
                child: const Text('Search'),
              ),
            ],
          ),
          const Space(),
          if (_searching) ...[
            const CircularProgressIndicator()
          ] else if (_searchFieldController.text.isEmpty) ...[
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                child: ListView(
                  scrollDirection: Axis.vertical,
                  children: [
                    const SizedBox(width: 500, height: 50),
                    Text(
                      "Looking around? Try these example queries:",
                      style: largeStyle,
                    ),
                    const Space(),
                    ExampleSearchBox(
                      query: "fairphone",
                      tip:
                          "Fairphone is a Dutch electronics manufacturer and social enterprise that designs and produces smartphones with the goal of having a lower environmental footprint and better social impact than is common in the industry.",
                      onSubmitted: _onExampleSubmitted,
                    ),
                    const Space(),
                    ExampleSearchBox(
                      query: "8717677339556",
                      tip:
                          "Did you find a barcode on a product and want to learn more? Just type it in the search box! (This one belongs to Tony's Chocolonely.)",
                      onSubmitted: _onExampleSubmitted,
                    ),
                    const Space(),
                    ExampleSearchBox(
                      query: "shein.com",
                      tip:
                          "Want to buy clothes online? Just enter the website address to learn if an ethical consumer should buy from there. (Spoiler: you shouldn't buy from SHEIN, but check it yourself!)",
                      onSubmitted: _onExampleSubmitted,
                    ),
                  ],
                ),
              ),
            ),
          ] else if (_entries.isNotEmpty) ...[
            Flexible(
              child: ListView(
                scrollDirection: Axis.vertical,
                children: [
                  for (final entry in _entries)
                    SearchEntryWidget(
                      entry: entry,
                      navigation: widget.navigation,
                    ),
                ],
              ),
            ),
          ] else ...[
            Center(child: Text("No results found", style: largeStyle)),
          ],
        ],
      ),
    );
  }

  Future<void> _onSubmitted(String text) async {
    if (_searching) {
      return;
    }
    setState(() {
      _searching = true;
      _entries = [];
    });
    final result = await widget.fetcher.textSearch(text);
    setState(() {
      _searching = false;
      _entries = result.results;
    });
  }

  Future<void> _onExampleSubmitted(String text) async {
    _searchFieldController.text = text;
    await _onSubmitted(text);
  }
}

class ProductArguments {
  final String id;

  ProductArguments({required this.id});
}

class ProductScreen extends StatelessWidget {
  final String? productId;
  final Navigation navigation;
  final api.Fetcher fetcher;

  const ProductScreen({
    super.key,
    required this.productId,
    required this.navigation,
    required this.fetcher,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Product"),
      ),
      body: ProductPage(
        productId: productId!,
        navigation: navigation,
        fetcher: fetcher,
      ),
    );
  }
}

class OrganisationArguments {
  final String id;

  OrganisationArguments({required this.id});
}

class OrganisationScreen extends StatelessWidget {
  final String organisationId;
  final api.Fetcher fetcher;
  final Navigation navigation;

  const OrganisationScreen({
    super.key,
    required this.organisationId,
    required this.fetcher,
    required this.navigation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Organisation"),
      ),
      body: OrganisationPage(
        organisationId: organisationId,
        navigation: navigation,
        fetcher: fetcher,
      ),
    );
  }
}

class LibraryArguments {
  final api.LibraryTopic topic;

  LibraryArguments({required this.topic});
}

class LibraryScreen extends StatelessWidget {
  final api.LibraryTopic topic;
  final api.Fetcher fetcher;
  final Navigation navigation;

  const LibraryScreen({
    super.key,
    required this.topic,
    required this.navigation,
    required this.fetcher,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Library"),
      ),
      body: LibraryItemView(
        topic: topic,
        fetcher: fetcher,
        navigation: navigation,
      ),
    );
  }
}

class RootScreen extends StatefulWidget {
  final api.Fetcher fetcher;
  final Navigation navigation;

  const RootScreen({
    super.key,
    required this.fetcher,
    required this.navigation,
  });

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> with TickerProviderStateMixin {
  static const int _tabNum = 5;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabNum, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sustainity'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.lightGreen[100],
          indicatorWeight: 7,
          tabs: const <Widget>[
            Tab(
              icon: Icon(Icons.home_outlined),
            ),
            Tab(
              icon: Icon(Icons.menu_book_outlined),
            ),
            Tab(
              icon: Icon(Icons.manage_search_outlined),
            ),
            Tab(
              icon: Icon(Icons.map_outlined),
            ),
            Tab(
              icon: Icon(Icons.qr_code_scanner_outlined),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          LibraryItemView(
            topic: api.LibraryTopic.main,
            fetcher: widget.fetcher,
            navigation: widget.navigation,
          ),
          LibraryPage(
            fetcher: widget.fetcher,
            navigation: widget.navigation,
          ),
          TextSearchPage(
            fetcher: widget.fetcher,
            navigation: widget.navigation,
          ),
          const Center(
            child: Text('There will be map search here.\n\nWork in progress!'),
          ),
          const Center(
            child: Text('There will be QRC search here.\n\nWork in progress!'),
          ),
        ],
      ),
    );
  }
}

enum NavigationPath {
  root,
  product,
  organisation,
  library,
}

class Navigation {
  static const rootPath = "/";
  static const productPath = "/product:";
  static const organisationPath = "/organisation:";
  static const libraryPath = "/library:";

  final BuildContext context;

  Navigation(this.context);

  void goToProduct(String productId) {
    Navigator.pushNamed(
      context,
      "$productPath$productId",
      arguments: AppArguments(
        NavigationPath.product,
        ProductArguments(id: productId),
      ),
    );
  }

  void goToOrganisation(String organisationId) {
    Navigator.pushNamed(
      context,
      "$organisationPath$organisationId",
      arguments: AppArguments(
        NavigationPath.organisation,
        OrganisationArguments(id: organisationId),
      ),
    );
  }

  void goToLibrary(api.LibraryTopic topic) {
    Navigator.pushNamed(
      context,
      "$libraryPath${topic.name}",
      arguments: AppArguments(
        NavigationPath.library,
        LibraryArguments(topic: topic),
      ),
    );
  }

  void onBadgeTap(api.BadgeName badge) {
    goToLibrary(badge.toLibraryTopic());
  }

  void onScorerTap(api.ScorerName scorer) {
    goToLibrary(scorer.toLibraryTopic());
  }
}

class AppArguments {
  final NavigationPath path;
  final dynamic args;

  AppArguments(this.path, this.args);
}

class SustainityFrontend extends StatefulWidget {
  final api.Fetcher fetcher;

  const SustainityFrontend({super.key, required this.fetcher});

  @override
  State<SustainityFrontend> createState() => _SustainityFrontendState();
}

class _SustainityFrontendState extends State<SustainityFrontend>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Sustainity',
        theme: ThemeData(
          cardColor: Colors.white,
          scaffoldBackgroundColor: Colors.grey[200],
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.green[800],
            foregroundColor: Colors.white,
          ),
          colorScheme: ColorScheme.fromSwatch().copyWith(
            primary: Colors.green[800],
            onPrimary: Colors.white,
          ),
        ),
        initialRoute: "/",
        onGenerateRoute: (settings) {
          AppArguments appArgs;
          if (settings.arguments != null) {
            appArgs = settings.arguments as AppArguments;
          } else {
            appArgs = parseArgs(settings.name);
          }
          switch (appArgs.path) {
            case NavigationPath.root:
              return MaterialPageRoute(
                settings: settings,
                builder: (context) {
                  return RootScreen(
                    fetcher: widget.fetcher,
                    navigation: Navigation(context),
                  );
                },
              );
            case NavigationPath.product:
              final args = appArgs.args as ProductArguments;
              return MaterialPageRoute(
                settings: settings,
                builder: (context) {
                  return ProductScreen(
                    productId: args.id,
                    fetcher: widget.fetcher,
                    navigation: Navigation(context),
                  );
                },
              );
            case NavigationPath.organisation:
              final args = appArgs.args as OrganisationArguments;
              return MaterialPageRoute(
                settings: settings,
                builder: (context) {
                  return OrganisationScreen(
                    organisationId: args.id,
                    fetcher: widget.fetcher,
                    navigation: Navigation(context),
                  );
                },
              );
            case NavigationPath.library:
              final args = appArgs.args as LibraryArguments;
              return MaterialPageRoute(
                settings: settings,
                builder: (context) {
                  return LibraryScreen(
                    topic: args.topic,
                    fetcher: widget.fetcher,
                    navigation: Navigation(context),
                  );
                },
              );
          }
        });
  }

  AppArguments parseArgs(String? path) {
    if (path == null || path == Navigation.rootPath) {
      return AppArguments(NavigationPath.root, null);
    }

    if (path.startsWith(Navigation.productPath)) {
      final productId = path.substring(Navigation.productPath.length);
      return AppArguments(
        NavigationPath.product,
        ProductArguments(id: productId),
      );
    }

    if (path.startsWith(Navigation.organisationPath)) {
      final organisationId = path.substring(Navigation.organisationPath.length);
      return AppArguments(
        NavigationPath.organisation,
        OrganisationArguments(id: organisationId),
      );
    }

    if (path.startsWith(Navigation.libraryPath)) {
      final topic = path.substring(Navigation.libraryPath.length);
      return AppArguments(
        NavigationPath.library,
        LibraryArguments(topic: api.LibraryTopicExtension.fromString(topic)),
      );
    }

    return AppArguments(NavigationPath.root, null);
  }
}
