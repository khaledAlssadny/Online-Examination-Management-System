using ITI.ExaminationSystem.Application.Messaging;
using MediatR;

namespace ITI.ExaminationSystem.UnitTests.Application.Messaging;

public sealed class MessagingFoundationTests
{
    [Fact]
    public void Commands_and_queries_are_application_owned_mediatr_requests()
    {
        Assert.True(typeof(IRequest<string>).IsAssignableFrom(typeof(TestCommand)));
        Assert.True(typeof(IRequest<string>).IsAssignableFrom(typeof(TestQuery)));
        Assert.Equal("ITI.ExaminationSystem.Application", typeof(ICommand<>).Assembly.GetName().Name);
        Assert.Equal("ITI.ExaminationSystem.Application", typeof(IQuery<>).Assembly.GetName().Name);
    }

    [Theory]
    [InlineData(true)]
    [InlineData(false)]
    public async Task MediatR_handlers_preserve_the_supplied_cancellation_token(bool command)
    {
        using CancellationTokenSource source = new();
        source.Cancel();

        OperationCanceledException exception = command
            ? await Assert.ThrowsAnyAsync<OperationCanceledException>(() =>
                ((IRequestHandler<TestCommand, string>)new TestCommandHandler()).Handle(new TestCommand(), source.Token))
            : await Assert.ThrowsAnyAsync<OperationCanceledException>(() =>
                ((IRequestHandler<TestQuery, string>)new TestQueryHandler()).Handle(new TestQuery(), source.Token));

        Assert.Equal(source.Token, exception.CancellationToken);
    }

    private sealed record TestCommand : ICommand<string>;
    private sealed record TestQuery : IQuery<string>;

    private sealed class TestCommandHandler : IRequestHandler<TestCommand, string>
    {
        public Task<string> Handle(TestCommand request, CancellationToken cancellationToken) =>
            Task.FromCanceled<string>(cancellationToken);
    }

    private sealed class TestQueryHandler : IRequestHandler<TestQuery, string>
    {
        public Task<string> Handle(TestQuery request, CancellationToken cancellationToken) =>
            Task.FromCanceled<string>(cancellationToken);
    }
}
