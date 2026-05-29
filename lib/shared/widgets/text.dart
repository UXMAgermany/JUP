import 'package:flutter/material.dart';

// Headline
class HeadlineLarge extends StatelessWidget {
  const HeadlineLarge({super.key, required this.text, this.overflow});
  final String text;
  final TextOverflow? overflow;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.headlineLarge,
      softWrap: true,
      overflow: overflow,
    );
  }
}

class HeadlineMedium extends StatelessWidget {
  const HeadlineMedium({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.headlineMedium);
  }
}

class HeadlineSmall extends StatelessWidget {
  const HeadlineSmall({super.key, required this.text, this.softWrap});
  final String text;
  final bool? softWrap;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.headlineSmall,
      softWrap: softWrap ?? true,
    );
  }
}

class HeadlineSmallEmphasized extends StatelessWidget {
  const HeadlineSmallEmphasized({super.key, required this.text, this.softWrap});
  final String text;
  final bool? softWrap;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w500),
      softWrap: softWrap ?? true,
      overflow:
          softWrap != false ? TextOverflow.visible : TextOverflow.ellipsis,
    );
  }
}

// Title
class TitleLarge extends StatelessWidget {
  const TitleLarge({
    super.key,
    required this.text,
    this.color,
    this.fontWeight,
  });
  final String text;
  final Color? color;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: fontWeight,
            overflow: TextOverflow.ellipsis,
          ),
    );
  }
}

class TitleLargeEmphasized extends StatelessWidget {
  const TitleLargeEmphasized({
    super.key,
    required this.text,
    this.color,
    this.softWrap,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });
  final String text;
  final Color? color;
  final bool? softWrap;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      softWrap: softWrap ?? true,
      maxLines: maxLines,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: color,
            overflow: overflow ?? TextOverflow.ellipsis,
          ),
    );
  }
}

class TitleMedium extends StatelessWidget {
  const TitleMedium({
    super.key,
    required this.text,
    this.color,
    this.softWrap,
    this.maxLines,
    this.overflow,
  });
  final String text;
  final Color? color;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
      overflow: overflow,
      maxLines: maxLines,
      softWrap: softWrap ?? true,
    );
  }
}

class TitleMediumEmphasized extends StatelessWidget {
  const TitleMediumEmphasized({
    super.key,
    required this.text,
    this.softWrap,
    this.maxLines,
    this.overflow,
  });
  final String text;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w600),
      overflow: overflow,
      maxLines: maxLines,
      softWrap: softWrap ?? true,
    );
  }
}

class TitleSmall extends StatelessWidget {
  const TitleSmall({super.key, required this.text, this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color),
    );
  }
}

// Body
class BodyLarge extends StatelessWidget {
  const BodyLarge({super.key, required this.text, this.color, this.fontWeight});
  final String text;
  final Color? color;
  final FontWeight? fontWeight;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodyLarge?.copyWith(color: color, fontWeight: fontWeight),
    );
  }
}

class BodyMedium extends StatelessWidget {
  const BodyMedium({
    super.key,
    required this.text,
    this.overflow,
    this.softWrap,
    this.color,
    this.maxLines,
    this.fontWeight,
  });
  final String text;
  final TextOverflow? overflow;
  final bool? softWrap;
  final Color? color;
  final int? maxLines;
  final FontWeight? fontWeight;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: color,
            overflow: overflow,
            fontWeight: fontWeight,
          ),
      maxLines: maxLines,
      softWrap: softWrap ?? true,
    );
  }
}

class BodySmall extends StatelessWidget {
  const BodySmall({super.key, required this.text, this.color, this.fontWeight});
  final String text;
  final Color? color;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodySmall!.copyWith(color: color, fontWeight: fontWeight),
    );
  }
}

// Label
class LabelLarge extends StatelessWidget {
  const LabelLarge({super.key, required this.text, this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
    );
  }
}

// Label
class LabelLargeEmphasized extends StatelessWidget {
  const LabelLargeEmphasized({super.key, required this.text, this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .labelLarge
          ?.copyWith(color: color, fontWeight: FontWeight.w600),
    );
  }
}

class LabelMedium extends StatelessWidget {
  const LabelMedium({super.key, required this.text, this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
    );
  }
}

class LabelSmall extends StatelessWidget {
  const LabelSmall({super.key, required this.text, this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
    );
  }
}

// Display
class DisplayLarge extends StatelessWidget {
  const DisplayLarge({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.displayLarge);
  }
}

class DisplayMedium extends StatelessWidget {
  const DisplayMedium({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.displayMedium);
  }
}

class DisplaySmall extends StatelessWidget {
  const DisplaySmall({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.displaySmall);
  }
}

class ErrorText extends StatelessWidget {
  const ErrorText({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium!.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
      softWrap: true,
      textAlign: TextAlign.center,
    );
  }
}
