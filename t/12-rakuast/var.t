use MONKEY-SEE-NO-EVAL;
use Test;

plan 71;

my $ast;   # so we don't need to repeat the "my" all the time

subtest 'Lexical variable lookup ($ sigil)' => {
    my $x = 42;

    # $x
    $ast := RakuAST::Var::Lexical.new('$x');
    is-deeply $_, 42
      for EVAL($ast), try EVAL($ast.DEPARSE);
}

subtest 'Lexical variable lookup (& sigil)' => {

    # &plan
    $ast := RakuAST::Var::Lexical.new('&plan');
    is-deeply $_, &plan
      for EVAL($ast), try EVAL($ast.DEPARSE);
}

subtest 'Positional capture variable lookup works' => {
    my $/;
    "abc" ~~ /(.)(.)/;

    # $0
    $ast := RakuAST::Var::PositionalCapture.new(0);
    is-deeply $_, "a"
      for EVAL($ast).Str, try EVAL($ast.DEPARSE).Str;

    # $1
    $ast := RakuAST::Var::PositionalCapture.new(1);
    is-deeply $_, "b"
      for EVAL($ast).Str, try EVAL($ast.DEPARSE).Str;
}

subtest 'Named capture variable lookup works' => {
    my $/;
    "abc" ~~ /$<x>=(.)$<y>=(.)/;

    # $<y>
    $ast := RakuAST::Var::NamedCapture.new(
      RakuAST::QuotedString.new(
        segments => [RakuAST::StrLiteral.new('y')]
      )
    );
    is-deeply $_, "b"
      for EVAL($ast).Str, try EVAL($ast.DEPARSE).Str;

    # $<x>
    $ast := RakuAST::Var::NamedCapture.new(
      RakuAST::QuotedString.new(
        segments => [RakuAST::StrLiteral.new('x')]
      )
    );
    is-deeply $_, "a"
      for EVAL($ast).Str, try EVAL($ast.DEPARSE).Str;
}

is-deeply  # my $foo = 10; $foo
    EVAL(RakuAST::StatementList.new(
        RakuAST::Statement::Expression.new(
            RakuAST::VarDeclaration::Simple.new(name => '$foo')
        ),
        RakuAST::Statement::Expression.new(
            RakuAST::ApplyInfix.new(
                left => RakuAST::Var::Lexical.new('$foo'),
                infix => RakuAST::Infix.new('='),
                right => RakuAST::IntLiteral.new(10)
            ),
        ),
        RakuAST::Statement::Expression.new(
            RakuAST::Var::Lexical.new('$foo')
        ),
    )),
    10,
    'Lexical variable declarations work';

{  # my $foo; $foo
    my \cont = EVAL(RakuAST::StatementList.new(
        RakuAST::Statement::Expression.new(
            RakuAST::VarDeclaration::Simple.new(name => '$foo')
        ),
        RakuAST::Statement::Expression.new(
            RakuAST::Var::Lexical.new('$foo')
        ),
    ));
    is-deeply cont, Any, 'Default value of untyped container is Any';
    ok cont.VAR.of =:= Mu, 'Default constraint of untyped container is Mu';
}

is-deeply  # my Int $foo; $foo = 99; $foo
    EVAL(RakuAST::StatementList.new(
        RakuAST::Statement::Expression.new(
            RakuAST::VarDeclaration::Simple.new(
                name => '$foo',
                type => RakuAST::Type::Simple.new(RakuAST::Name.from-identifier('Int')),
            )
        ),
        RakuAST::Statement::Expression.new(
            RakuAST::ApplyInfix.new(
                left => RakuAST::Var::Lexical.new('$foo'),
                infix => RakuAST::Infix.new('='),
                right => RakuAST::IntLiteral.new(99)
            ),
        ),
        RakuAST::Statement::Expression.new(
            RakuAST::Var::Lexical.new('$foo')
        ),
    )),
    99,
    'Typed variable declarations work (type matches in assignment)';

throws-like
    {  # my Int $foo; $foo = 1e5; $foo
        EVAL(RakuAST::StatementList.new(
            RakuAST::Statement::Expression.new(
                RakuAST::VarDeclaration::Simple.new(
                    name => '$foo',
                    type => RakuAST::Type::Simple.new(RakuAST::Name.from-identifier('Int')),
                )
            ),
            RakuAST::Statement::Expression.new(
                RakuAST::ApplyInfix.new(
                    left => RakuAST::Var::Lexical.new('$foo'),
                    infix => RakuAST::Infix.new('='),
                    right => RakuAST::NumLiteral.new(1e5)
                ),
            ),
            RakuAST::Statement::Expression.new(
                RakuAST::Var::Lexical.new('$foo')
            ),
        ))
    },
    X::TypeCheck::Assignment,
    expected => Int,
    got => 1e5,
    'Typed variable declarations work (type mismatch throws)';

{  # my $var = 125; $var
    my \result = EVAL(RakuAST::StatementList.new(
        RakuAST::Statement::Expression.new(
            RakuAST::VarDeclaration::Simple.new(
                name => '$var',
                initializer => RakuAST::Initializer::Assign.new(RakuAST::IntLiteral.new(125))
            )
        ),
        RakuAST::Statement::Expression.new(
            RakuAST::Var::Lexical.new('$var')
        ),
    ));
    is-deeply result, 125,
        'Lexical variable declarations with assignment initializer';
    ok result.VAR.isa(Scalar),
        'Really was an assignment into a Scalar container';
    nok result.VAR.dynamic, 'Is not dynamic';
    lives-ok { result = 42 },
        'Can update the container that was produced';
}

{  # my @var = 22, 33; @var
    my \result = EVAL(RakuAST::StatementList.new(
        RakuAST::Statement::Expression.new(
            RakuAST::VarDeclaration::Simple.new(
                name => '@var',
                initializer => RakuAST::Initializer::Assign.new(
                    RakuAST::ApplyListInfix.new(
                        infix => RakuAST::Infix.new(','),
                        operands => (RakuAST::IntLiteral.new(22), RakuAST::IntLiteral.new(33))
                    )
                )
            )
        ),
        RakuAST::Statement::Expression.new(
            RakuAST::Var::Lexical.new('@var')
        ),
    ));
    is-deeply result, [22,33],
        'Lexical array declarations with assignment initializer works';
}

{  # my $var := 225
    my \result = EVAL(RakuAST::StatementList.new(
        RakuAST::Statement::Expression.new(
            RakuAST::VarDeclaration::Simple.new(
                name => '$var',
                initializer => RakuAST::Initializer::Bind.new(RakuAST::IntLiteral.new(225))
            )
        ),
        RakuAST::Statement::Expression.new(
            RakuAST::Var::Lexical.new('$var')
        ),
    ));
    is-deeply result, 225,
        'Lexical variable declarations with bind initializer';
    nok result.VAR.isa(Scalar),
        'Really was bound; no Scalar container';
    dies-ok { result = 42 },
        'Cannot assign as it is not a container';
}

{  # $*dyn
    sub with-dyn(&test) {
        my $*dyn = 'in';
    }
    my $*dyn = 'out';
    is-deeply EVAL(RakuAST::Var::Dynamic.new('$*dyn')), 'out',
        'Dynamic variable access (1)';
    is-deeply with-dyn({ EVAL(RakuAST::Var::Dynamic.new('$*dyn')) }), 'in',
        'Dynamic variable access (2)';
    is-deeply EVAL(RakuAST::Var::Dynamic.new('$*OUT')), $*OUT,
        'Dynamic variable fallback also works';
}

{  # my $*var = 360;
    my \result = EVAL(RakuAST::StatementList.new(
        RakuAST::Statement::Expression.new(
            RakuAST::VarDeclaration::Simple.new(
                name => '$*var',
                initializer => RakuAST::Initializer::Assign.new(RakuAST::IntLiteral.new(360))
            )
        ),
        RakuAST::Statement::Expression.new(
            RakuAST::Var::Dynamic.new('$*var')
        ),
    ));
    is-deeply result, 360,
        'Dynamic variable declarations with assignment initializer, dynamic lookup';
    ok result.VAR.isa(Scalar),
        'Dynamic did an assignment into a Scalar container';
    ok result.VAR.dynamic, 'Is a dynamic';
    lives-ok { result = 99 },
        'Can update the container that was produced';
}

{  # my @arr; @arr
    my \cont = EVAL(RakuAST::StatementList.new(
        RakuAST::Statement::Expression.new(
            RakuAST::VarDeclaration::Simple.new(name => '@arr')
        ),
        RakuAST::Statement::Expression.new(
            RakuAST::Var::Lexical.new('@arr')
        ),
    ));
    is-deeply cont.WHAT, Array, '@ sigil var is initialized to Array';
    is-deeply cont.VAR.WHAT, Array, '@ sigil var not wrapped in Scalar';
    ok cont.defined, 'It is a defined Array instance';
    is cont.elems, 0, 'It is empty';
    is-deeply cont[0].VAR.WHAT, Scalar, 'Element is a Scalar';
    is-deeply cont[0], Any, 'Contains an Any by default';
    ok cont[0].VAR.of =:= Mu, 'Constraint is Mu by default';
}

{  # my %hash; %hash
    my \cont = EVAL(RakuAST::StatementList.new(
        RakuAST::Statement::Expression.new(
            RakuAST::VarDeclaration::Simple.new(name => '%hash')
        ),
        RakuAST::Statement::Expression.new(
            RakuAST::Var::Lexical.new('%hash')
        ),
    ));
    is-deeply cont.WHAT, Hash, '% sigil var is initialized to Hash';
    is-deeply cont.VAR.WHAT, Hash, '% sigil var not wrapped in Scalar';
    ok cont.defined, 'It is a defined Hash instance';
    is cont.elems, 0, 'It is empty';
    is-deeply cont<k>.VAR.WHAT, Scalar, 'Element is a Scalar';
    is-deeply cont<k>, Any, 'Contains an Any by default';
    ok cont<k>.VAR.of =:= Mu, 'Constraint is Mu by default';
}

{  # my Int @arr; @arr
    my \cont = EVAL(RakuAST::StatementList.new(
        RakuAST::Statement::Expression.new(
            RakuAST::VarDeclaration::Simple.new(
                name => '@arr',
                type => RakuAST::Type::Simple.new(RakuAST::Name.from-identifier('Int'))
            ),
        ),
        RakuAST::Statement::Expression.new(
            RakuAST::Var::Lexical.new('@arr')
        ),
    ));
    ok cont ~~ Array, '@ sigil var with Int type is an Array';
    ok cont ~~ Positional[Int], 'It does Positional[Int]';
    is-deeply cont.of, Int, '.of gives Int';
    is cont.elems, 0, 'It is empty';
    is-deeply cont[0].VAR.WHAT, Scalar, 'Element is a Scalar';
    is-deeply cont[0], Int, 'Contains an Int';
    ok cont[0].VAR.of =:= Int, 'Constraint is Int';
}

{  # my Int %hash; %hash
    my \cont = EVAL(RakuAST::StatementList.new(
        RakuAST::Statement::Expression.new(
            RakuAST::VarDeclaration::Simple.new(
                name => '%hash',
                type => RakuAST::Type::Simple.new(RakuAST::Name.from-identifier('Int'))
            ),
        ),
        RakuAST::Statement::Expression.new(
            RakuAST::Var::Lexical.new('%hash')
        ),
    ));
    ok cont ~~ Hash, '% sigil var with Int type is a Hash';
    ok cont ~~ Associative[Int], 'It does Associative[Int]';
    is-deeply cont.of, Int, '.of gives Int';
    is cont.elems, 0, 'It is empty';
    is-deeply cont<k>.VAR.WHAT, Scalar, 'Element is a Scalar';
    is-deeply cont<k>, Int, 'Contains an Int';
    ok cont<k>.VAR.of =:= Int, 'Constraint is Int';
}

{  # $x
    my int $x = 42;
    is-deeply EVAL(RakuAST::Var::Lexical.new('$x')),
        42,
        'Can access external native int var';
}

{  # $x
    my num $x = 4e2;
    is-deeply EVAL(RakuAST::Var::Lexical.new('$x')),
        4e2,
        'Can access external native num var';
}

{  # $x
    my str $x = 'answer';
    is-deeply EVAL(RakuAST::Var::Lexical.new('$x')),
        'answer',
        'Can access external native str var';
}

{  # my int $native-int; $native-int
    my \cont = EVAL(RakuAST::StatementList.new(
        RakuAST::Statement::Expression.new(
            RakuAST::VarDeclaration::Simple.new(
                name => '$native-int',
                type => RakuAST::Type::Simple.new(RakuAST::Name.from-identifier('int'))
            ),
        ),
        RakuAST::Statement::Expression.new(
            RakuAST::Var::Lexical.new('$native-int')
        ),
    ));
    my $desc = 'int declaration creates a native int container';
    multi check(int $x) { pass $desc }
    multi check($x) { flunk $desc }
    check(cont);
    is-deeply cont, 0, 'Native int initialized to 0 by default';
}

{  # my num $native-num; $native-num
    my \cont = EVAL(RakuAST::StatementList.new(
        RakuAST::Statement::Expression.new(
            RakuAST::VarDeclaration::Simple.new(
                name => '$native-num',
                type => RakuAST::Type::Simple.new(RakuAST::Name.from-identifier('num'))
            ),
        ),
        RakuAST::Statement::Expression.new(
            RakuAST::Var::Lexical.new('$native-num')
        ),
    ));
    my $desc = 'num declaration creates a native num container';
    multi check(num $x) { pass $desc }
    multi check($x) { flunk $desc }
    check(cont);
    is-deeply cont, 0e0, 'Native num initialized to 0e0 by default';
}

{  # my str $native-str; $native-str
    my \cont = EVAL(RakuAST::StatementList.new(
        RakuAST::Statement::Expression.new(
            RakuAST::VarDeclaration::Simple.new(
                name => '$native-str',
                type => RakuAST::Type::Simple.new(RakuAST::Name.from-identifier('str'))
            ),
        ),
        RakuAST::Statement::Expression.new(
            RakuAST::Var::Lexical.new('$native-str')
        ),
    ));
    my $desc = 'str declaration creates a native str container';
    multi check(str $x) { pass $desc }
    multi check($x) { flunk $desc }
    check(cont);
    is-deeply cont, '', 'Native str initialized to empty string by default';
}

{  # my int $native-int = 963; $native-int
    my \cont = EVAL(RakuAST::StatementList.new(
        RakuAST::Statement::Expression.new(
            RakuAST::VarDeclaration::Simple.new(
                name => '$native-int',
                type => RakuAST::Type::Simple.new(RakuAST::Name.from-identifier('int')),
                initializer => RakuAST::Initializer::Assign.new(RakuAST::IntLiteral.new(963))
            ),
        ),
        RakuAST::Statement::Expression.new(
            RakuAST::Var::Lexical.new('$native-int')
        ),
    ));
    is-deeply cont, 963, 'Native int assign initializer works';
}

{  # my num $native-num = 96e3; $native-num
    my \cont = EVAL(RakuAST::StatementList.new(
        RakuAST::Statement::Expression.new(
            RakuAST::VarDeclaration::Simple.new(
                name => '$native-num',
                type => RakuAST::Type::Simple.new(RakuAST::Name.from-identifier('num')),
                initializer => RakuAST::Initializer::Assign.new(RakuAST::NumLiteral.new(96e3))
            ),
        ),
        RakuAST::Statement::Expression.new(
            RakuAST::Var::Lexical.new('$native-num')
        ),
    ));
    is-deeply cont, 96e3, 'Native num assign initializer works';
}

{  # my str $native-str = 'nine six three'; $native-str
    my \cont = EVAL(RakuAST::StatementList.new(
        RakuAST::Statement::Expression.new(
            RakuAST::VarDeclaration::Simple.new(
                name => '$native-str',
                type => RakuAST::Type::Simple.new(RakuAST::Name.from-identifier('str')),
                initializer => RakuAST::Initializer::Assign.new(RakuAST::StrLiteral.new('nine six three'))
            ),
        ),
        RakuAST::Statement::Expression.new(
            RakuAST::Var::Lexical.new('$native-str')
        ),
    ));
    is-deeply cont, 'nine six three', 'Native str assign initializer works';
}

{
    my module M {
        our $var = 66;
        is-deeply  # our $var; $var
            EVAL(RakuAST::StatementList.new(
                RakuAST::Statement::Expression.new(
                    RakuAST::VarDeclaration::Simple.new(
                        scope => 'our',
                        name => '$var',
                    ),
                ),
                RakuAST::Statement::Expression.new(
                    RakuAST::Var::Lexical.new('$var')
                ),
            )),
            66,
            'our-scoped variable declaration without initializer takes current value (eval mode)';
        is-deeply $var, 66, 'Value of our-scoped package variable intact after EVAL';

        is-deeply  # our $x = 42; $x
            EVAL(RakuAST::StatementList.new(
                RakuAST::Statement::Expression.new(
                    RakuAST::VarDeclaration::Simple.new(
                        scope => 'our',
                        name => '$x',
                        initializer => RakuAST::Initializer::Assign.new(RakuAST::IntLiteral.new(42))
                    ),
                ),
                RakuAST::Statement::Expression.new(
                    RakuAST::Var::Lexical.new('$x')
                ),
            )),
            42,
            'our-scoped variable declaration with initializer works (eval mode)';

        is-deeply  # our $y = 99; $y
            EVAL(RakuAST::CompUnit.new(
                :!eval,
                :comp-unit-name('TEST_1'),
                :statement-list(RakuAST::StatementList.new(
                    RakuAST::Statement::Expression.new(
                        RakuAST::VarDeclaration::Simple.new(
                            scope => 'our',
                            name => '$y',
                            initializer => RakuAST::Initializer::Assign.new(RakuAST::IntLiteral.new(99))
                        ),
                    ),
                    RakuAST::Statement::Expression.new(
                        RakuAST::Var::Lexical.new('$y')
                    )
                ))
            )),
            99,
            'our-scoped variable declaration with initializer works (top-level mode)';
    }
    is-deeply $M::x, 42, 'our variable set in eval mode is installed into the current package';
    ok $M::x.VAR ~~ Scalar, 'It is a bound scalar';
    nok M.WHO<$y>:exists, 'our-scoped variable declaration in top-level comp unit does not leak out';
}
