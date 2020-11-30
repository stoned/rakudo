use MONKEY-SEE-NO-EVAL;
use Test;

plan 33;

{
    my $x = 12;
    my $y = 99;
    is-deeply
            EVAL(RakuAST::StatementList.new(
                RakuAST::Statement::Expression.new(
                    RakuAST::ApplyPrefix.new(
                        prefix => RakuAST::Prefix.new('++'),
                        operand => RakuAST::Var::Lexical.new('$x'))),
                RakuAST::Statement::Expression.new(
                    RakuAST::ApplyPrefix.new(
                        prefix => RakuAST::Prefix.new('++'),
                        operand => RakuAST::Var::Lexical.new('$y')))
            )),
            100,
            'Statement list evaluates to its final statement';
    is $x, 13, 'First side-effecting statement was executed';
    is $y, 100, 'Second side-effecting statement was executed';
}

{
    my ($a, $b, $c);

    my $test-ast := RakuAST::Statement::If.new(
        condition => RakuAST::Var::Lexical.new('$a'),
        then => RakuAST::Block.new(body =>
            RakuAST::Blockoid.new(
                RakuAST::StatementList.new(
                    RakuAST::Statement::Expression.new(
                        RakuAST::IntLiteral.new(1)
                    )))),
        elsifs => [
            RakuAST::Statement::Elsif.new(
                condition => RakuAST::Var::Lexical.new('$b'),
                then => RakuAST::Block.new(body =>
                    RakuAST::Blockoid.new(
                        RakuAST::StatementList.new(
                            RakuAST::Statement::Expression.new(
                                RakuAST::IntLiteral.new(2)
                            ))))),
            RakuAST::Statement::Elsif.new(
                condition => RakuAST::Var::Lexical.new('$c'),
                then => RakuAST::Block.new(body =>
                    RakuAST::Blockoid.new(
                        RakuAST::StatementList.new(
                            RakuAST::Statement::Expression.new(
                                RakuAST::IntLiteral.new(3)
                            ))))),
        ],
        else => RakuAST::Block.new(body =>
            RakuAST::Blockoid.new(
                RakuAST::StatementList.new(
                    RakuAST::Statement::Expression.new(
                        RakuAST::IntLiteral.new(4)
                    ))))
    );

    $a = $b = $c = False;
    is-deeply EVAL($test-ast), 4, 'When all conditions False, else is evaluated';

    $c = True;
    is-deeply EVAL($test-ast), 3, 'Latest elsif reachable when matched';

    $b = True;
    is-deeply EVAL($test-ast), 2, 'First elsif reachable when matched';

    $a = True;
    is-deeply EVAL($test-ast), 1, 'When the main condition is true, the then block is picked';
}

{
    my $a;

    my $test-ast := RakuAST::Statement::If.new(
        condition => RakuAST::Var::Lexical.new('$a'),
        then => RakuAST::Block.new(body =>
            RakuAST::Blockoid.new(
                RakuAST::StatementList.new(
                    RakuAST::Statement::Expression.new(
                        RakuAST::IntLiteral.new(1)
                    ))))
    );

    $a = True;
    is-deeply EVAL($test-ast), 1, 'When simple if with no else has true condition, evaluates to branch';

    $a = False;
    is-deeply EVAL($test-ast), Empty, 'When simple if with no else has false condition, evaluates to Empty';
}

{
    my ($a, $b, $c);

    my $test-ast := RakuAST::Statement::With.new(
        condition => RakuAST::Var::Lexical.new('$a'),
        then => RakuAST::PointyBlock.new(
            signature => RakuAST::Signature.new(
                parameters => (
                    RakuAST::Parameter.new(
                        target => RakuAST::ParameterTarget::Var.new('$x')
                    ),
                )
            ),
            body => RakuAST::Blockoid.new(
                RakuAST::StatementList.new(
                    RakuAST::Statement::Expression.new(
                        RakuAST::IntLiteral.new(1)
                    )))),
        elsifs => [
            RakuAST::Statement::Orwith.new(
                condition => RakuAST::Var::Lexical.new('$b'),
                then => RakuAST::PointyBlock.new(
                    signature => RakuAST::Signature.new(
                        parameters => (
                            RakuAST::Parameter.new(
                                target => RakuAST::ParameterTarget::Var.new('$x')
                            ),
                        )
                    ),
                    body => RakuAST::Blockoid.new(
                        RakuAST::StatementList.new(
                            RakuAST::Statement::Expression.new(
                                RakuAST::IntLiteral.new(2)
                            ))))),
            RakuAST::Statement::Orwith.new(
                condition => RakuAST::Var::Lexical.new('$c'),
                then => RakuAST::PointyBlock.new(
                    signature => RakuAST::Signature.new(
                        parameters => (
                            RakuAST::Parameter.new(
                                target => RakuAST::ParameterTarget::Var.new('$x')
                            ),
                        )
                    ),
                    body => RakuAST::Blockoid.new(
                        RakuAST::StatementList.new(
                            RakuAST::Statement::Expression.new(
                                RakuAST::IntLiteral.new(3)
                            ))))),
        ],
        else => RakuAST::PointyBlock.new(
            signature => RakuAST::Signature.new(
                parameters => (
                    RakuAST::Parameter.new(
                        target => RakuAST::ParameterTarget::Var.new('$x')
                    ),
                )
            ),
            body => RakuAST::Blockoid.new(
                RakuAST::StatementList.new(
                    RakuAST::Statement::Expression.new(
                        RakuAST::IntLiteral.new(4)
                    ))))
    );

    $a = $b = $c = Nil;
    is-deeply EVAL($test-ast), 4, 'When all conditions undefined, else is evaluated';

    $c = False;
    is-deeply EVAL($test-ast), 3, 'Latest orwith reachable when matched';

    $b = False;
    is-deeply EVAL($test-ast), 2, 'First orwith reachable when matched';

    $a = False;
    is-deeply EVAL($test-ast), 1, 'When the main condition is defined, the then block is picked';
}

{
    my $a;

    my $test-ast := RakuAST::Statement::With.new(
        condition => RakuAST::Var::Lexical.new('$a'),
        then => RakuAST::PointyBlock.new(
            signature => RakuAST::Signature.new(
                parameters => (
                    RakuAST::Parameter.new(
                        target => RakuAST::ParameterTarget::Var.new('$x')
                    ),
                )
            ),
            body => RakuAST::Blockoid.new(
                RakuAST::StatementList.new(
                    RakuAST::Statement::Expression.new(
                        RakuAST::IntLiteral.new(1)
                    ))))
    );

    $a = False;
    is-deeply EVAL($test-ast), 1, 'When simple when with no else has defined condition, evaluates to branch';

    $a = Nil;
    is-deeply EVAL($test-ast), Empty, 'When simple with if with no else has undefined condition, evaluates to Empty';
}

{
    my $x = False;
    my $y = 9;
    is-deeply
            EVAL(RakuAST::Statement::Unless.new(
                condition => RakuAST::Var::Lexical.new('$x'),
                body => RakuAST::Block.new(body =>
                    RakuAST::Blockoid.new(
                        RakuAST::StatementList.new(
                            RakuAST::Statement::Expression.new(
                                RakuAST::ApplyPrefix.new(
                                    prefix => RakuAST::Prefix.new('++'),
                                    operand => RakuAST::Var::Lexical.new('$y'))))))
            )),
            10,
            'An unless block with a false condition evaluates to its body';
    is $y, 10, 'Side-effect of the body was performed';
}

{
    my $x = True;
    my $y = 9;
    is-deeply
            EVAL(RakuAST::Statement::Unless.new(
                condition => RakuAST::Var::Lexical.new('$x'),
                body => RakuAST::Block.new(body =>
                    RakuAST::Blockoid.new(
                        RakuAST::StatementList.new(
                            RakuAST::Statement::Expression.new(
                                RakuAST::ApplyPrefix.new(
                                    prefix => RakuAST::Prefix.new('++'),
                                    operand => RakuAST::Var::Lexical.new('$y'))))))
            )),
            Empty,
            'An unless block with a false condition evaluates to Empty';
    is $y, 9, 'Side-effect of the body was not performed';
}

{
    my $x = Nil;
    my $y = 9;
    is-deeply
            EVAL(RakuAST::Statement::Without.new(
                condition => RakuAST::Var::Lexical.new('$x'),
                body => RakuAST::Block.new(body =>
                    RakuAST::Blockoid.new(
                        RakuAST::StatementList.new(
                            RakuAST::Statement::Expression.new(
                                RakuAST::ApplyPostfix.new(
                                    postfix => RakuAST::Postfix.new('++'),
                                    operand => RakuAST::Var::Lexical.new('$y'))))))
            )),
            9,
            'An without block with an undefined object evaluates to its body';
    is $y, 10, 'Side-effect of the body was performed';
}

{
    my $x = True;
    my $y = 9;
    is-deeply
            EVAL(RakuAST::Statement::Without.new(
                condition => RakuAST::Var::Lexical.new('$x'),
                body => RakuAST::Block.new(body =>
                    RakuAST::Blockoid.new(
                        RakuAST::StatementList.new(
                            RakuAST::Statement::Expression.new(
                                RakuAST::ApplyPrefix.new(
                                    prefix => RakuAST::Prefix.new('++'),
                                    operand => RakuAST::Var::Lexical.new('$y'))))))
            )),
            Empty,
            'An without block with a defined object evaluates to Empty';
    is $y, 9, 'Side-effect of the body was not performed';
}

{
    my $x = 5;
    is-deeply
        EVAL(RakuAST::Statement::Loop::While.new(
            condition => RakuAST::Var::Lexical.new('$x'),
            body => RakuAST::Block.new(body =>
                RakuAST::Blockoid.new(
                    RakuAST::StatementList.new(
                        RakuAST::Statement::Expression.new(
                            RakuAST::ApplyPrefix.new(
                                prefix => RakuAST::Prefix.new('--'),
                                operand => RakuAST::Var::Lexical.new('$x')))))))),
        Nil,
        'While loop at statement level evaluates to Nil';
    is-deeply $x, 0, 'Loop variable was decremented to zero';
}

{
    my $x = 5;
    is-deeply
        EVAL(RakuAST::Statement::Loop::Until.new(
            condition => RakuAST::ApplyPrefix.new(
                prefix => RakuAST::Prefix.new('!'),
                operand => RakuAST::Var::Lexical.new('$x')
            ),
            body => RakuAST::Block.new(body =>
                RakuAST::Blockoid.new(
                    RakuAST::StatementList.new(
                        RakuAST::Statement::Expression.new(
                            RakuAST::ApplyPrefix.new(
                                prefix => RakuAST::Prefix.new('--'),
                                operand => RakuAST::Var::Lexical.new('$x')))))))),
        Nil,
        'Until loop at statement level evaluates to Nil';
    is-deeply $x, 0, 'Loop variable was decremented to zero';
}

{
    my $x = 0;
    is-deeply
        EVAL(RakuAST::Statement::Loop::RepeatUntil.new(
            condition => RakuAST::Var::Lexical.new('$x'),
            body => RakuAST::Block.new(body =>
                RakuAST::Blockoid.new(
                    RakuAST::StatementList.new(
                        RakuAST::Statement::Expression.new(
                            RakuAST::ApplyPrefix.new(
                                prefix => RakuAST::Prefix.new('--'),
                                operand => RakuAST::Var::Lexical.new('$x')))))))),
        Nil,
        'Repeat while loop at statement level evaluates to Nil';
    is-deeply $x, -1, 'Repeat while loop ran once';
}

{
    my $count = 0;
    is-deeply
        EVAL(RakuAST::Statement::Loop.new(
            setup => RakuAST::VarDeclaration::Simple.new(
                name => '$i',
                initializer => RakuAST::Initializer::Assign.new(
                    RakuAST::IntLiteral.new(9)
                )
            ),
            condition => RakuAST::Var::Lexical.new('$i'),
            increment => RakuAST::ApplyPrefix.new(
                prefix => RakuAST::Prefix.new('--'),
                operand => RakuAST::Var::Lexical.new('$i')
            ),
            body => RakuAST::Block.new(body =>
                RakuAST::Blockoid.new(
                    RakuAST::StatementList.new(
                        RakuAST::Statement::Expression.new(
                            RakuAST::ApplyPrefix.new(
                                prefix => RakuAST::Prefix.new('++'),
                                operand => RakuAST::Var::Lexical.new('$count')))))))),
        Nil,
        'Loop block with setup and increment expression evalutes to Nil';
    is-deeply $count, 9, 'Loop with setup/increment runs as expected';
}

{
    my $count = 0;
    is-deeply
        EVAL(RakuAST::Statement::For.new(
            source => RakuAST::ApplyInfix.new(
                left => RakuAST::IntLiteral.new(2),
                infix => RakuAST::Infix.new('..'),
                right => RakuAST::IntLiteral.new(7)
            ),
            body => RakuAST::PointyBlock.new(
                signature => RakuAST::Signature.new(
                    parameters => (
                        RakuAST::Parameter.new(
                            target => RakuAST::ParameterTarget::Var.new('$x')
                        ),
                    )
                ),
                body => RakuAST::Blockoid.new(
                    RakuAST::StatementList.new(
                        RakuAST::Statement::Expression.new(
                            RakuAST::ApplyPrefix.new(
                                prefix => RakuAST::Prefix.new('++'),
                                operand => RakuAST::Var::Lexical.new('$count')))))))),
        Nil,
        'Statement level for loop evalutes to Nil';
    is-deeply $count, 6, 'For loop does expected number of iterations';
}
