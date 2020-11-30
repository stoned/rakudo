use MONKEY-SEE-NO-EVAL;
use Test;

plan 67;

sub rx(RakuAST::Regex $body) {
    EVAL RakuAST::QuotedRegex.new(:$body)
}

{
    # / foo /
    is "foobarbaz" ~~ rx(RakuAST::Regex::Literal.new('foo')),
        'foo',
        'Simple literal regex matches at start of string';
    # / foo /
    is "42foobarbaz" ~~ rx(RakuAST::Regex::Literal.new('foo')),
        'foo',
        'Simple literal regex matches in middle of string';
    # / foo /
    nok "barbaz" ~~ rx(RakuAST::Regex::Literal.new('foo')),
        'String without literal is not matched';

    # / b || bc /
    is "abcd" ~~ rx(RakuAST::Regex::SequentialAlternation.new(
            RakuAST::Regex::Literal.new('b'),
            RakuAST::Regex::Literal.new('bc'))),
        'b',
        'Sequential alternation of literals takes first match even if second is longer';
    # / x || bc /
    is "abcd" ~~ rx(RakuAST::Regex::SequentialAlternation.new(
            RakuAST::Regex::Literal.new('x'),
            RakuAST::Regex::Literal.new('bc'))),
        'bc',
        'Sequential alternation of literals takes second match if first fails';

    # / x || y /
    nok "abcd" ~~ rx(RakuAST::Regex::SequentialAlternation.new(
            RakuAST::Regex::Literal.new('x'),
            RakuAST::Regex::Literal.new('y'))),
        'Sequential alternation of literals fails if no alternative matches';

    # / b | bc /
    is "abcd" ~~ rx(RakuAST::Regex::Alternation.new(
            RakuAST::Regex::Literal.new('b'),
            RakuAST::Regex::Literal.new('bc'))),
        'bc',
        'LTM alternation of literals takes longest match even if it is not first';
    # / x | bc /
    is "abcd" ~~ rx(RakuAST::Regex::Alternation.new(
            RakuAST::Regex::Literal.new('x'),
            RakuAST::Regex::Literal.new('bc'))),
        'bc',
        'Alternation of literals takes second match if first fails';
    # / x | y /
    nok "abcd" ~~ rx(RakuAST::Regex::Alternation.new(
            RakuAST::Regex::Literal.new('x'),
            RakuAST::Regex::Literal.new('y'))),
        'Alternation of literals fails if no alternative matches';

    # / . && c /
    is "abcd" ~~ rx(RakuAST::Regex::Conjunction.new(
            RakuAST::Regex::CharClass::Any.new,
            RakuAST::Regex::Literal.new('c'))),
        'c',
        'Conjunction matches when both items match';
    # / . && x /
    nok "abcd" ~~ rx(RakuAST::Regex::Conjunction.new(
            RakuAST::Regex::CharClass::Any.new,
            RakuAST::Regex::Literal.new('x'))),
        'Conjunction fails when one item does not match';
    # / . && cd
    nok "abcd" ~~ rx(RakuAST::Regex::Conjunction.new(
            RakuAST::Regex::CharClass::Any.new,
            RakuAST::Regex::Literal.new('cd'))),
        'Conjunction fails when items match different lengths';

    # / . d /
    is "abcde" ~~ rx(RakuAST::Regex::Sequence.new(
            RakuAST::Regex::CharClass::Any.new,
            RakuAST::Regex::Literal.new('d'))),
        'cd',
        'Sequence needs one thing to match after the other (pass case)';
    # / . a /
    nok "abcde" ~~ rx(RakuAST::Regex::Sequence.new(
            RakuAST::Regex::CharClass::Any.new,
            RakuAST::Regex::Literal.new('a'))),
        'Sequence needs one thing to match after the other (failure case)';

    # / ^ . /
    is "abcde" ~~ rx(RakuAST::Regex::Sequence.new(
            RakuAST::Regex::Anchor::BeginningOfString.new,
            RakuAST::Regex::CharClass::Any.new)),
        'a',
        'Beginning of string anchor works (pass case)';
    # / ^ b /
    nok "abcde" ~~ rx(RakuAST::Regex::Sequence.new(
            RakuAST::Regex::Anchor::BeginningOfString.new,
            RakuAST::Regex::Literal.new('b'))),
        'Beginning of string anchor works (failure case)';

    # / . $ /
    is "abcde" ~~ rx(RakuAST::Regex::Sequence.new(
            RakuAST::Regex::CharClass::Any.new,
            RakuAST::Regex::Anchor::EndOfString.new)),
        'e',
        'End of string anchor works (pass case)';
    # / b $ /
    nok "abcde" ~~ rx(RakuAST::Regex::Sequence.new(
            RakuAST::Regex::Literal.new('b'),
            RakuAST::Regex::Anchor::EndOfString.new)),
        'End of string anchor works (failure case)';

    # / . e >> /
    is "elizabeth the second" ~~ rx(RakuAST::Regex::Sequence.new(
            RakuAST::Regex::CharClass::Any.new,
            RakuAST::Regex::Literal.new('e'),
            RakuAST::Regex::Anchor::RightWordBoundary.new)),
        'he',
        'Right word boundary works (pass case)';
    # / . e >> /
    nok "elizabeth second" ~~ rx(RakuAST::Regex::Sequence.new(
            RakuAST::Regex::CharClass::Any.new,
            RakuAST::Regex::Literal.new('e'),
            RakuAST::Regex::Anchor::RightWordBoundary.new)),
        'Right word boundary works (failure case)';

    # / << . t /
    is "cat ethics committee" ~~ rx(RakuAST::Regex::Sequence.new(
            RakuAST::Regex::Anchor::LeftWordBoundary.new,
            RakuAST::Regex::CharClass::Any.new,
            RakuAST::Regex::Literal.new('t'))),
        'et',
        'Left word boundary works (pass case)';
    # / << . t /
    nok "cat committee" ~~ rx(RakuAST::Regex::Sequence.new(
            RakuAST::Regex::Anchor::LeftWordBoundary.new,
            RakuAST::Regex::CharClass::Any.new,
            RakuAST::Regex::Literal.new('t'))),
        'Left word boundary works (failure case)';

    # / \d+ /
    is "99cents" ~~ rx(RakuAST::Regex::QuantifiedAtom.new(
            atom => RakuAST::Regex::CharClass::Digit.new,
            quantifier => RakuAST::Regex::Quantifier::OneOrMore.new)),
        '99',
        'Quantified built-in character class matches';
    # / \D+ /
    is "99cents" ~~ rx(RakuAST::Regex::QuantifiedAtom.new(
            atom => RakuAST::Regex::CharClass::Digit.new(:negated),
            quantifier => RakuAST::Regex::Quantifier::OneOrMore.new)),
        'cents',
        'Quantified negated built-in character class matches';
    # / \d+? /
    is "99cents" ~~ rx(RakuAST::Regex::QuantifiedAtom.new(
            atom => RakuAST::Regex::CharClass::Digit.new,
            quantifier => RakuAST::Regex::Quantifier::OneOrMore.new(
                backtrack => RakuAST::Regex::Backtrack::Frugal
            ))),
        '9',
        'Quantified built-in character class matches (frugal mode)';
    # / \D+? /
    is "99cents" ~~ rx(RakuAST::Regex::QuantifiedAtom.new(
            atom => RakuAST::Regex::CharClass::Digit.new(:negated),
            quantifier => RakuAST::Regex::Quantifier::OneOrMore.new(
                backtrack => RakuAST::Regex::Backtrack::Frugal
            ))),
        'c',
        'Quantified negated built-in character class matches (frugal mode)';

    # / ^ \d+ 9 /
    is "99cents" ~~ rx(RakuAST::Regex::Sequence.new(
            RakuAST::Regex::Anchor::BeginningOfString.new,
            RakuAST::Regex::QuantifiedAtom.new(
                atom => RakuAST::Regex::CharClass::Digit.new,
                quantifier => RakuAST::Regex::Quantifier::OneOrMore.new
            ),
            RakuAST::Regex::Literal.new('9'),
        )),
        '99',
        'Greedy quantifier will backtrack';
    # / ^ \d+: 9 /
    nok "99cents" ~~ rx(RakuAST::Regex::Sequence.new(
            RakuAST::Regex::Anchor::BeginningOfString.new,
            RakuAST::Regex::QuantifiedAtom.new(
                atom => RakuAST::Regex::CharClass::Digit.new,
                quantifier => RakuAST::Regex::Quantifier::OneOrMore.new(
                    backtrack => RakuAST::Regex::Backtrack::Ratchet
                )
            ),
            RakuAST::Regex::Literal.new('9'),
        )),
        'Ratchet quantifier will not backtrack';

    # / \d+ % ',' / 
    is "values: 1,2,3,4,stuff" ~~ rx(RakuAST::Regex::QuantifiedAtom.new(
            atom => RakuAST::Regex::CharClass::Digit.new,
            quantifier => RakuAST::Regex::Quantifier::OneOrMore.new,
            separator => RakuAST::Regex::Literal.new(','))),
        '1,2,3,4',
        'Separator works (non-trailing case)';
    # / \d+ %% ',' / 
    is "values: 1,2,3,4,stuff" ~~ rx(RakuAST::Regex::QuantifiedAtom.new(
            atom => RakuAST::Regex::CharClass::Digit.new,
            quantifier => RakuAST::Regex::Quantifier::OneOrMore.new,
            separator => RakuAST::Regex::Literal.new(','),
            trailing-separator => True)),
        '1,2,3,4,',
        'Separator works (trailing case)';
    # / \d+ % ',' / 
    is "values: 1,2,33,4,stuff" ~~ rx(RakuAST::Regex::QuantifiedAtom.new(
            atom => RakuAST::Regex::CharClass::Digit.new,
            quantifier => RakuAST::Regex::Quantifier::OneOrMore.new,
            separator => RakuAST::Regex::Literal.new(','))),
        '1,2,3',
        'Separator must be between every quantified item';

    # / [\d+]+ % ',' /
    is "values: 1,2,33,400,stuff" ~~ rx(RakuAST::Regex::QuantifiedAtom.new(
            atom => RakuAST::Regex::Group.new(
                RakuAST::Regex::QuantifiedAtom.new(
                    atom => RakuAST::Regex::CharClass::Digit.new,
                    quantifier => RakuAST::Regex::Quantifier::OneOrMore.new
                )
            ),
            quantifier => RakuAST::Regex::Quantifier::OneOrMore.new,
            separator => RakuAST::Regex::Literal.new(','))),
        '1,2,33,400',
        'Regex groups compile correctly';
    nok $/.list.keys, 'No positional captures from non-capturing group';
    nok $/.hash.keys, 'No named captures from non-capturing group';

    is "1a2" ~~ rx(RakuAST::Regex::Assertion::Named.new(
            name => RakuAST::Name.from-identifier('alpha'),
            capturing => True
        )),
        'a',
        'Named assertion matches correctly';
    is-deeply $/.hash.keys, ('alpha',).Seq, 'Correct match keys';
    is $<alpha>, 'a', 'Correct match captured';

    is "1a2" ~~ rx(RakuAST::Regex::Assertion::Alias.new(
            name => 'foo',
            assertion => RakuAST::Regex::Assertion::Named.new(
                name => RakuAST::Name.from-identifier('alpha'),
                capturing => True
            )
        )),
        'a',
        'Named assertion with alias matches correctly';
    is-deeply $/.hash.keys.sort, ('alpha', 'foo').Seq, 'Correct match keys';
    is $<alpha>, 'a', 'Correct match captured (original name)';
    is $<foo>, 'a', 'Correct match captured (aliased name)';

    is "1a2" ~~ rx(RakuAST::Regex::Assertion::Named.new(
            name => RakuAST::Name.from-identifier('alpha'),
            capturing => False
        )),
        'a',
        'Non-capturing named assertion matches correctly';
    is-deeply $/.hash.keys, ().Seq, 'No match keys';

    is "1a2" ~~ rx(RakuAST::Regex::Assertion::Alias.new(
            name => 'foo',
            assertion => RakuAST::Regex::Assertion::Named.new(
                name => RakuAST::Name.from-identifier('alpha'),
                capturing => False
            )
        )),
        'a',
        'Non-capturing named assertion with alias matches correctly';
    is-deeply $/.hash.keys.sort, ('foo',).Seq, 'Correct match keys';
    is $<foo>, 'a', 'Correct match captured (aliased name)';

    is "2a1b" ~~ rx(RakuAST::Regex::Sequence.new(
            RakuAST::Regex::CapturingGroup.new(
                RakuAST::Regex::CharClass::Word.new
            ),
            RakuAST::Regex::CharClass::Digit.new,
            RakuAST::Regex::CapturingGroup.new(
                RakuAST::Regex::CharClass::Word.new
            )
        )),
        'a1b',
        'Regex with two positional capturing groups matches correctly';
    is $/.list.elems, 2, 'Two positional captures';
    is $0, 'a', 'First positional capture is correct';
    is $1, 'b', 'Second positional capture is correct';
    nok $/.hash, 'No named captures';

    is "!2a" ~~ rx(RakuAST::Regex::Sequence.new(
            RakuAST::Regex::Assertion::Lookahead.new(
                assertion => RakuAST::Regex::Assertion::Named.new(
                    name => RakuAST::Name.from-identifier('alpha'),
                    capturing => True
                )
            ),
            RakuAST::Regex::CharClass::Word.new
        )),
        'a',
        'Lookahead assertion with named rule works';
    is $/.list.elems, 0, 'No positional captures';
    is $/.hash.elems, 0, 'No named captures';

    is "!2a" ~~ rx(RakuAST::Regex::Sequence.new(
            RakuAST::Regex::Assertion::Lookahead.new(
                negated => True,
                assertion => RakuAST::Regex::Assertion::Named.new(
                    name => RakuAST::Name.from-identifier('alpha'),
                    capturing => True
                )
            ),
            RakuAST::Regex::CharClass::Word.new
        )),
        '2',
        'Negated lookahead assertion with named rule works';
    is $/.list.elems, 0, 'No positional captures';
    is $/.hash.elems, 0, 'No named captures';

    is "!2a" ~~ rx(RakuAST::Regex::Sequence.new(
            RakuAST::Regex::Assertion::Lookahead.new(
                assertion => RakuAST::Regex::Assertion::Named::RegexArg.new(
                    name => RakuAST::Name.from-identifier('before'),
                    regex-arg => RakuAST::Regex::CharClass::Digit.new,
                )
            ),
            RakuAST::Regex::CharClass::Word.new
        )),
        '2',
        'Lookahead assertion calling before with a regex arg works';
    is $/.list.elems, 0, 'No positional captures';
    is $/.hash.elems, 0, 'No named captures';

    is "!2a" ~~ rx(RakuAST::Regex::Sequence.new(
            RakuAST::Regex::Assertion::Lookahead.new(
                negated => True,
                assertion => RakuAST::Regex::Assertion::Named::RegexArg.new(
                    name => RakuAST::Name.from-identifier('before'),
                    regex-arg => RakuAST::Regex::CharClass::Digit.new,
                )
            ),
            RakuAST::Regex::CharClass::Word.new
        )),
        'a',
        'Negated lookahead assertion calling before with a regex arg works';
    is $/.list.elems, 0, 'No positional captures';
    is $/.hash.elems, 0, 'No named captures';

    is "a1b2c" ~~ rx(RakuAST::Regex::Sequence.new(
            RakuAST::Regex::Literal.new('b'),
            RakuAST::Regex::MatchFrom.new,
            RakuAST::Regex::CharClass::Digit.new,
            RakuAST::Regex::MatchTo.new,
            RakuAST::Regex::Literal.new('c'))),
        '2',
        'Match from and match to markers works';

    is "believe" ~~ rx(RakuAST::Regex::Quote.new(RakuAST::QuotedString.new(
            :segments[RakuAST::StrLiteral.new('lie')]
        ))),
        'lie',
        'Match involving a quoted string literal works';

    my $end = 've';
    is "believe" ~~ EVAL(RakuAST::QuotedRegex.new(body =>
            RakuAST::Regex::Quote.new(RakuAST::QuotedString.new(
                :segments[RakuAST::StrLiteral.new('e'), RakuAST::Var::Lexical.new('$end')]
            ))
        )),
        'eve',
        'Match involving a quoted string with interpolation works';

    is "slinky spring" ~~ rx(RakuAST::Regex::Quote.new(RakuAST::QuotedString.new(
            :segments[RakuAST::StrLiteral.new('link inky linky')],
            :processors['words']
        ))),
        'linky',
        'Match involving quote words works';
}

# vim: expandtab shiftwidth=4
