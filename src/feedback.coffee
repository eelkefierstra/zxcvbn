scoring = require('./scoring')

feedback =
  default_feedback:
    warning: ''
    suggestions: [
      "Gebruik meerdere woorden, vermijd bekende uitspraken"
      "Symbolen, cijfers of hoofdletters zijn niet verplicht"
    ]

  get_feedback: (score, sequence) ->
    # starting feedback
    return @default_feedback if sequence.length == 0

    # no feedback if score is good or great.
    return if score > 2
      warning: ''
      suggestions: []

    # tie feedback to the longest match for longer sequences
    longest_match = sequence[0]
    for match in sequence[1..]
      longest_match = match if match.token.length > longest_match.token.length
    feedback = @get_match_feedback(longest_match, sequence.length == 1)
    extra_feedback = 'Voeg nog een aantal woorden toe. Onbekender is beter.'
    if feedback?
      feedback.suggestions.unshift extra_feedback
      feedback.warning = '' unless feedback.warning?
    else
      feedback =
        warning: ''
        suggestions: [extra_feedback]
    feedback

  get_match_feedback: (match, is_sole_match) ->
    switch match.pattern
      when 'dictionary'
        @get_dictionary_match_feedback match, is_sole_match

      when 'spatial'
        layout = match.graph.toUpperCase()
        warning = if match.turns == 1
          'Een rij op het toetsenbord is makkelijk te raden'
        else
          'Korte patronen op het toetsenbord zijn makkelijk te raden'
        warning: warning
        suggestions: [
          'Gebruik een langer patroon met meer bochten'
        ]

      when 'repeat'
        warning = if match.base_token.length == 1
          'Herhalingen zoals "aaa" zijn makkelijk te raden'
        else
          'Herhalingen zoals "abcabcabc" zijn maar een klein beetje moeilijker te raden dan "abc"'
        warning: warning
        suggestions: [
          'Vermijd het herhalen van woorden en letters'
        ]

      when 'sequence'
        warning: "Reeksen zoals abc of 6543 zijn makkelijk te raden"
        suggestions: [
          'Vermijd reeksen'
        ]

      when 'regex'
        if match.regex_name == 'recent_year'
          warning: "Recente jaartallen zijn makkelijk te raden"
          suggestions: [
            'Vermijd recente jaartallen'
            'Vermijd jaartallen die aan jou gerelateerd zijn'
          ]

      when 'date'
        warning: "Datum zijn vaak makkelijk te raden"
        suggestions: [
          'Vermijd datums en jaartallen die aan jou gerelateerd zijn'
        ]

  get_dictionary_match_feedback: (match, is_sole_match) ->
    warning = if match.dictionary_name == 'passwords'
      if is_sole_match and not match.l33t and not match.reversed
        if match.rank <= 10
          'Dit is een top-10 veelvoorkomend wachtwoord'
        else if match.rank <= 100
          'Dit is een top-100 veelvoorkomend wachtwoord'
        else
          'Dit is een veelvoorkomend wachtwoord'
      else if match.guesses_log10 <= 4
        'Dit lijkt op een veelvoorkomend wachtwoord'
    else if match.dictionary_name in ['english_wikipedia', 'nld_wikipedia', 'nl_subtitles', 'nld_news']
      if is_sole_match
        'Een woord op zich is makkelijk te raden'
    else if match.dictionary_name in ['surnames', 'male_names', 'female_names']
      if is_sole_match
        'Namen zijn makkelijk te raden'
      else
        'Bekende namen zijn makkelijk te raden'
    else
      ''

    suggestions = []
    word = match.token
    if word.match(scoring.START_UPPER)
      suggestions.push "Hoofdletters helpen niet veel"
    else if word.match(scoring.ALL_UPPER) and word.toLowerCase() != word
      suggestions.push "Alleen hoofdletters is bijna net zo makkelijk te raden als alleen kleine letters"

    if match.reversed and match.token.length >= 4
      suggestions.push "Woorden achterstevoren zijn niet veel moeilijker om te raden"
    if match.l33t
      suggestions.push "Voorspelbare vervangers zoals '@' in plaats van 'a' helpen niet veel"

    result =
      warning: warning
      suggestions: suggestions
    result

module.exports = feedback
