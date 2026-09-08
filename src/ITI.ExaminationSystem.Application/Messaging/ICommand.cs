using MediatR;

namespace ITI.ExaminationSystem.Application.Messaging;

public interface ICommand<out TResponse> : IRequest<TResponse>;
