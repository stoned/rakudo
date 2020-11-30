use MONKEY-SEE-NO-EVAL;
use Test;

plan 25;

{
    my $block := EVAL RakuAST::StatementList.new(
        RakuAST::Statement::Expression.new(
            RakuAST::PointyBlock.new(
                signature => RakuAST::Signature.new(
                    parameters => ()
                ),
                body => RakuAST::Blockoid.new(RakuAST::StatementList.new(
                    RakuAST::Statement::Expression.new(
                        RakuAST::IntLiteral.new(101)
                    )
                ))
            )
        )
    );
    ok $block.WHAT === Block, 'A pointy block node evaluates to a Block';
    is $block.signature.params.elems, 0, 'The block has no parameters';
    is-deeply $block.arity, 0, 'The block has 0 arity';
    is-deeply $block.count, 0, 'The block has 0 count';
    is $block(), 101, 'Invoking the block returns the expected value';
    dies-ok { $block(1) }, 'Invoking the block with an argument dies';
}

{
    my $block := EVAL RakuAST::StatementList.new(
        RakuAST::Statement::Expression.new(
            RakuAST::PointyBlock.new(
                signature => RakuAST::Signature.new(
                    parameters => (
                        RakuAST::Parameter.new(
                            target => RakuAST::ParameterTarget::Var.new('$param')
                        ),
                    )
                ),
                body => RakuAST::Blockoid.new(RakuAST::StatementList.new(
                    RakuAST::Statement::Expression.new(
                        RakuAST::Var::Lexical.new('$param')
                    )
                ))
            )
        )
    );
    ok $block.WHAT === Block, 'A pointy block node taking a parameter evaluates to a Block';
    is $block.signature.params.elems, 1, 'The block has one parameters';
    is-deeply $block.arity, 1, 'The block has 1 arity';
    is-deeply $block.count, 1, 'The block has 1 count';
    is $block(199), 199, 'Invoking the block with an argument returns the expected value';
    dies-ok { $block(my $a = 42) = 1 }, 'Argument is bound read-only';
    dies-ok { $block() }, 'Invoking the block without an argument dies';
}

{
    my $x = 99;
    my $result := EVAL RakuAST::StatementList.new(
        RakuAST::Statement::Expression.new(
            RakuAST::Block.new(
                body => RakuAST::Blockoid.new(RakuAST::StatementList.new(
                    RakuAST::Statement::Expression.new(
                        RakuAST::ApplyPostfix.new(
                            operand => RakuAST::Var::Lexical.new('$x'),
                            postfix => RakuAST::Postfix.new('++')
                        )
                    )
                ))
            )
        )
    );
    is-deeply $result, 99, 'Bare block at statement level is executed';
    is-deeply $x, 100, 'Side-effects were performed as expected';
}

{
    my $x = 99;
    my $result := EVAL RakuAST::StatementList.new(
        RakuAST::Statement::Expression.new(
            RakuAST::Circumfix::Parentheses.new(
                RakuAST::SemiList.new(
                    RakuAST::Statement::Expression.new(
                        RakuAST::Block.new(
                            body => RakuAST::Blockoid.new(RakuAST::StatementList.new(
                                RakuAST::Statement::Expression.new(
                                    RakuAST::ApplyPostfix.new(
                                        operand => RakuAST::Var::Lexical.new('$x'),
                                        postfix => RakuAST::Postfix.new('++')
                                    )
                                )
                            ))
                        )
                    )
                )
            )
        )
    );
    is-deeply $result.WHAT, Block, 'Bare block in parentheses evaluates to Block';
    is-deeply $x, 99, 'No side-effects were performed';
    is-deeply $result(), 99, 'Can evaluate the returned block';
    is-deeply $x, 100, 'Block did perform side-effects when evaluated';
}

{
    my $sub := EVAL RakuAST::StatementList.new(
        RakuAST::Statement::Expression.new(
            RakuAST::Sub.new(
                signature => RakuAST::Signature.new(
                    parameters => (
                        RakuAST::Parameter.new(
                            target => RakuAST::ParameterTarget::Var.new('$param')
                        ),
                    )
                ),
                body => RakuAST::Blockoid.new(RakuAST::StatementList.new(
                    RakuAST::Statement::Expression.new(
                        RakuAST::Var::Lexical.new('$param')
                    )
                ))
            )
        )
    );
    ok $sub.WHAT === Sub, 'A sub node evaluates to a Sub';
    is $sub.signature.params.elems, 1, 'The sub has one parameter';
    is-deeply $sub.arity, 1, 'The block has 1 arity';
    is-deeply $sub.count, 1, 'The block has 1 count';
    is $sub(189), 189, 'Invoking the sub with an argument returns the expected value';
    dies-ok { $sub() }, 'Invoking the sub without an argument dies';
}
