using MediatR;

namespace ITI.ExaminationSystem.Application.Messaging;

public interface IQuery<out TResponse> : IRequest<TResponse>;
