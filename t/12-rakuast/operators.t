use MONKEY-SEE-NO-EVAL;
use Test;

plan 21;

is-deeply
        EVAL(RakuAST::ApplyInfix.new(
            left => RakuAST::IntLiteral.new(44),
            infix => RakuAST::Infix.new('+'),
            right => RakuAST::IntLiteral.new(22)
        )),
        66,
        'Application of an infix operator on two literals';

{
    is-deeply
            EVAL(RakuAST::ApplyInfix.new(
                left => RakuAST::IntLiteral.new(22),
                infix => RakuAST::Infix.new('||'),
                right => RakuAST::IntLiteral.new(44)
            )),
            22,
            'The special form || operator works (1)';
    is-deeply
            EVAL(RakuAST::ApplyInfix.new(
                left => RakuAST::IntLiteral.new(0),
                infix => RakuAST::Infix.new('||'),
                right => RakuAST::IntLiteral.new(44)
            )),
            44,
            'The special form || operator works (2)';

    is-deeply
            EVAL(RakuAST::ApplyInfix.new(
                left => RakuAST::IntLiteral.new(22),
                infix => RakuAST::Infix.new('or'),
                right => RakuAST::IntLiteral.new(44)
            )),
            22,
            'The special form or operator works (1)';
    is-deeply
            EVAL(RakuAST::ApplyInfix.new(
                left => RakuAST::IntLiteral.new(0),
                infix => RakuAST::Infix.new('or'),
                right => RakuAST::IntLiteral.new(44)
            )),
            44,
            'The special form or operator works (2)';

    is-deeply
            EVAL(RakuAST::ApplyInfix.new(
                left => RakuAST::IntLiteral.new(22),
                infix => RakuAST::Infix.new('&&'),
                right => RakuAST::IntLiteral.new(44)
            )),
            44,
            'The special form && operator works (1)';
    is-deeply
            EVAL(RakuAST::ApplyInfix.new(
                left => RakuAST::IntLiteral.new(0),
                infix => RakuAST::Infix.new('&&'),
                right => RakuAST::IntLiteral.new(44)
            )),
            0,
            'The special form && operator works (2)';

    is-deeply
            EVAL(RakuAST::ApplyInfix.new(
                left => RakuAST::IntLiteral.new(22),
                infix => RakuAST::Infix.new('and'),
                right => RakuAST::IntLiteral.new(44)
            )),
            44,
            'The special form and operator works (1)';
    is-deeply
            EVAL(RakuAST::ApplyInfix.new(
                left => RakuAST::IntLiteral.new(0),
                infix => RakuAST::Infix.new('and'),
                right => RakuAST::IntLiteral.new(44)
            )),
            0,
            'The special form and operator works (2)';
}

is-deeply
        EVAL(RakuAST::ApplyPrefix.new(
            prefix => RakuAST::Prefix.new('?'),
            operand => RakuAST::IntLiteral.new(2)
        )),
        True,
        'Application of a prefix operator to a literal (1)';

is-deeply
        EVAL(RakuAST::ApplyPrefix.new(
            prefix => RakuAST::Prefix.new('?'),
            operand => RakuAST::IntLiteral.new(0)
        )),
        False,
        'Application of a prefix operator to a literal (2)';

{
    sub postfix:<!>($n) {
        [*] 1..$n
    }
    is-deeply
            EVAL(RakuAST::ApplyPostfix.new(
                operand => RakuAST::IntLiteral.new(4),
                postfix => RakuAST::Postfix.new('!'),
            )),
            24,
            'Application of a (user-defined) postfix operator to a literal';
}

{
    my $a = 1;
    is-deeply
        EVAL(RakuAST::ApplyInfix.new(
            left => RakuAST::Var::Lexical.new('$a'),
            infix => RakuAST::Infix.new('='),
            right => RakuAST::IntLiteral.new(4)
        )),
        4,
        'Basic assignment to a Scalar container';
}

{
    my @a = 10..20;
    is-deeply
        EVAL(RakuAST::ApplyPostfix.new(
            operand => RakuAST::Var::Lexical.new('@a'),
            postfix => RakuAST::Postcircumfix::ArrayIndex.new(
                RakuAST::SemiList.new(
                    RakuAST::Statement::Expression.new(
                        RakuAST::IntLiteral.new(5)
                    )
                )
            )
        )),
        15,
        'Basic single-dimension array index';

    is-deeply
        EVAL(RakuAST::ApplyPostfix.new(
            operand => RakuAST::Var::Lexical.new('@a'),
            postfix => RakuAST::Postcircumfix::ArrayIndex.new(
                RakuAST::SemiList.new()
            )
        )),
        @a,
        'Zen array slice';
}

{
    my @a[3;3] = <a b c>, <d e f>, <g h i>;
    is-deeply
        EVAL(RakuAST::ApplyPostfix.new(
            operand => RakuAST::Var::Lexical.new('@a'),
            postfix => RakuAST::Postcircumfix::ArrayIndex.new(
                RakuAST::SemiList.new(
                    RakuAST::Statement::Expression.new(
                        RakuAST::IntLiteral.new(2)
                    ),
                    RakuAST::Statement::Expression.new(
                        RakuAST::IntLiteral.new(1)
                    )
                )
            )
        )),
        'h',
        'Multi-dimensional array indexing';
}

{
    my %h = a => 'add', s => 'subtract';
    is-deeply
        EVAL(RakuAST::ApplyPostfix.new(
            operand => RakuAST::Var::Lexical.new('%h'),
            postfix => RakuAST::Postcircumfix::HashIndex.new(
                RakuAST::SemiList.new(
                    RakuAST::Statement::Expression.new(
                        RakuAST::StrLiteral.new('s')
                    )
                )
            )
        )),
        'subtract',
        'Basic single-dimension hash index';

    is-deeply
        EVAL(RakuAST::ApplyPostfix.new(
            operand => RakuAST::Var::Lexical.new('%h'),
            postfix => RakuAST::Postcircumfix::HashIndex.new(
                RakuAST::SemiList.new()
            )
        )),
        %h,
        'Zen hash slice';
}

{
    my %h = x => { :1a, :2b }, y => { :3a, :4b };
    is-deeply
        EVAL(RakuAST::ApplyPostfix.new(
            operand => RakuAST::Var::Lexical.new('%h'),
            postfix => RakuAST::Postcircumfix::HashIndex.new(
                RakuAST::SemiList.new(
                    RakuAST::Statement::Expression.new(
                        RakuAST::StrLiteral.new('y')
                    ),
                    RakuAST::Statement::Expression.new(
                        RakuAST::StrLiteral.new('a')
                    )
                )
            )
        )),
        (3,), # Is this actually a CORE.setting bug?
        'Multi-dimensional hash indexing';
}

is-deeply
        EVAL(RakuAST::ApplyListInfix.new(
            infix => RakuAST::Infix.new(','),
            operands => (
                RakuAST::IntLiteral.new(10),
                RakuAST::IntLiteral.new(11),
                RakuAST::IntLiteral.new(12),
            )
        )),
        (10, 11, 12),
        'Application of a list infix operator on three operands';

is-deeply
        EVAL(RakuAST::ApplyListInfix.new(
            infix => RakuAST::Infix.new(','),
            operands => ()
        )),
        (),
        'Application of a list infix operator on no operands';
